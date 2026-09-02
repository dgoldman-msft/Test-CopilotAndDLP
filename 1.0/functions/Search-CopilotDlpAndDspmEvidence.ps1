function Search-CopilotDlpAndDspmEvidence {
    <#
    .SYNOPSIS
    Retrieves unified audit, DSPM, and DLP alert evidence for Copilot tests.

    .DESCRIPTION
    Runs all correlation paths for one Copilot ConversationId, pipeline input,
    or every record in a Test-CopilotAndDLP JSONL result file. Each output object
    contains exact ConversationId matches from the unified audit log and DSPM
    Activity Explorer, plus the corresponding Microsoft Graph DLP alert summary.

    Each source is queried independently. If one source fails, results from the
    other sources are retained and the source-specific error is returned in
    UnifiedAuditError, DspmError, or DlpAlertError.

    Exchange Online (unified audit) and Security & Compliance PowerShell (DSPM)
    connections are reused automatically for every record processed in this call,
    and for later calls in the same PowerShell process, as long as the existing
    connection's token is still active. Microsoft Graph DLP-alert correlation for
    every record runs through a single isolated child process per call, so only
    one Graph sign-in is needed regardless of how many records are in ResultPath.

    .PARAMETER ConversationId
    Copilot conversation ID to investigate. When the user and start time aren't
    supplied, the command derives them from the exact unified-audit or DSPM
    conversation match before searching for a corresponding DLP alert.

    .PARAMETER UserPrincipalName
    Test user. Accepts TestUser by property name.

    .PARAMETER ResultPath
    Test-CopilotAndDLP JSONL file containing all validation records to inspect.
    When called directly (not from the pipeline) with no -ConversationId,
    -UserPrincipalName, or -ResultPath, the command looks for
    copilot-dlp-results.jsonl in the current directory and uses it automatically;
    if that file doesn't exist, it throws asking for -ConversationId.

    .PARAMETER StartDateUtc
    Validation start time. Accepts StartedAtUtc by property name.

    .PARAMETER EndDateUtc
    End of the correlation search window.

    .PARAMETER TenantId
    Microsoft Entra tenant ID or verified tenant domain.

    .PARAMETER SkipDlpAlert
    Omits Microsoft Graph alerts_v2 correlation when only unified audit and DSPM
    evidence are required.

    .PARAMETER UseDeviceCode
    Uses device-code authentication for unified-audit and Microsoft Graph alert
    connections. Without this switch, interactive authentication is used.

    .PARAMETER ConversationIdLookbackDays
    When -ConversationId is supplied directly with no -StartDateUtc, and that
    conversation isn't in the default copilot-dlp-results.jsonl file, how many
    days to look back instead of the usual two-hour default. Applies to
    ConversationId values obtained from the Purview alerts portal rather than a
    saved run. Defaults to 7.

    .EXAMPLE
    Search-CopilotDlpAndDspmEvidence `
        -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
        -UserPrincipalName 'dlp-tester@contoso.example' `
        -StartDateUtc '2026-09-02T15:00:00Z'

    Returns all available evidence for one conversation.

    .EXAMPLE
    Search-CopilotDlpAndDspmEvidence -ResultPath './copilot-dlp-results.jsonl'

    Returns all available evidence for every saved validation record.

    .EXAMPLE
    Search-CopilotDlpAndDspmEvidence

    Called with no arguments in the directory containing copilot-dlp-results.jsonl,
    returns evidence for every record in that file automatically.

    .EXAMPLE
    Search-CopilotDlpAndDspmEvidence -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5'

    A ConversationId copied from the Purview alerts portal's Correlation ID field,
    with no -StartDateUtc supplied. The command looks it up in
    copilot-dlp-results.jsonl first; if it isn't there, it searches the last 7
    days instead of the usual two-hour default.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $ConversationId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('TestUser')]
        [string] $UserPrincipalName,

        [Alias('Path')]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string] $ResultPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('StartedAtUtc')]
        [datetime] $StartDateUtc = (Get-Date).ToUniversalTime().AddHours(-2),

        [datetime] $EndDateUtc = (Get-Date).ToUniversalTime(),

        [string] $TenantId,

        [switch] $SkipDlpAlert,

        [switch] $UseDeviceCode,

        [ValidateRange(1, 90)]
        [int] $ConversationIdLookbackDays = 7
    )

    process {
        if (-not $ResultPath -and -not $ConversationId -and -not $UserPrincipalName -and -not $MyInvocation.ExpectingInput) {
            $defaultResultPath = Join-Path (Get-Location).Path 'copilot-dlp-results.jsonl'
            if (Test-Path -LiteralPath $defaultResultPath -PathType Leaf) {
                Write-Verbose "No -ConversationId, -UserPrincipalName, or -ResultPath was supplied; defaulting to the results file at '$defaultResultPath'."
                $ResultPath = $defaultResultPath
            }
            else {
                throw "Specify -ConversationId, -UserPrincipalName, or -ResultPath. No default result file was found at '$defaultResultPath'."
            }
        }

        if ($ConversationId -and -not $PSBoundParameters.ContainsKey('StartDateUtc') -and -not $MyInvocation.ExpectingInput) {
            $resolved = Resolve-CopilotDlpConversationWindow -ConversationId $ConversationId -UserPrincipalName $UserPrincipalName -LookbackDays $ConversationIdLookbackDays
            Write-Verbose "No -StartDateUtc was supplied for conversation '$ConversationId'; using $($resolved.Source)."
            $StartDateUtc = $resolved.StartDateUtc
            if ($resolved.UserPrincipalName) {
                $UserPrincipalName = $resolved.UserPrincipalName
            }
        }

        if ($ResultPath -and ($ConversationId -or $UserPrincipalName)) {
            throw "Use -ResultPath by itself; don't combine it with -ConversationId or -UserPrincipalName."
        }

        $records = if ($ResultPath) {
            @(Get-Content -LiteralPath $ResultPath | ConvertFrom-Json)
        }
        else {
            @([pscustomobject]@{
                RunId              = $null
                ConversationId     = $ConversationId
                TestUser           = $UserPrincipalName
                StartedAtUtc       = $StartDateUtc
                SubmissionStatus   = $null
                ExpectedDlpOutcome = $null
            })
        }

        # Phase 1: collect unified-audit and DSPM evidence per record, and queue any
        # Graph DLP-alert lookups so they can run through one isolated process below.
        $recordStates = [Collections.Generic.List[pscustomobject]]::new()
        $alertParameterSets = [Collections.Generic.List[hashtable]]::new()

        foreach ($record in $records) {
            if ([string]::IsNullOrWhiteSpace([string] $record.ConversationId)) {
                throw 'A ConversationId is required directly, through pipeline input, or in each ResultPath record.'
            }

            $common = @{
                ConversationId = [string] $record.ConversationId
                StartDateUtc   = [datetime] $record.StartedAtUtc
                EndDateUtc     = $EndDateUtc
            }
            if ($record.TestUser) {
                $common.UserPrincipalName = [string] $record.TestUser
            }
            if ($TenantId) {
                $common.TenantId = $TenantId
            }
            $unifiedAuditError = $null
            $dspmError = $null

            try {
                $auditParameters = $common.Clone()
                if ($UseDeviceCode) {
                    $auditParameters.UseDeviceCode = $true
                }
                $unifiedAudit = @(Search-CopilotDlpAuditEvent @auditParameters -ErrorAction Stop)
            }
            catch {
                $unifiedAudit = @()
                $unifiedAuditError = $_.Exception.Message
                Write-Warning "Unified audit lookup failed for conversation '$($record.ConversationId)': $unifiedAuditError"
            }

            $effectiveUser = [string] $record.TestUser
            $effectiveStart = [datetime] $record.StartedAtUtc
            $startDerivedFromEvidence = $false
            if (-not $effectiveUser -and $unifiedAudit.Count -gt 0) {
                $effectiveUser = [string] $unifiedAudit[0].UserId
            }
            if ($unifiedAudit.Count -gt 0 -and -not $PSBoundParameters.ContainsKey('StartDateUtc') -and -not $ResultPath) {
                # Guard against a Local/Unspecified-tagged CreationTime that is already numerically UTC, so it isn't shifted again downstream.
                $candidateStart = [datetime] $unifiedAudit[0].CreationTime
                $effectiveStart = if ($candidateStart.Kind -eq [DateTimeKind]::Utc) { $candidateStart } else { [DateTime]::SpecifyKind($candidateStart, [DateTimeKind]::Utc) }
                $startDerivedFromEvidence = $true
            }

            try {
                $dspmParameters = $common.Clone()
                # Use the more precise start time derived from unified audit, if one was found,
                # instead of the original (possibly stale, e.g. a reused ConversationId's old
                # saved run time) record start, to keep the DSPM search window tight and valid.
                $dspmParameters.StartDateUtc = $effectiveStart
                $dspm = @(Search-CopilotDlpDspmEvent @dspmParameters -ErrorAction Stop -WarningAction SilentlyContinue)
            }
            catch {
                $dspm = @()
                $dspmError = $_.Exception.Message
                Write-Warning "DSPM Activity Explorer lookup failed for conversation '$($record.ConversationId)': $dspmError"
            }

            if (-not $effectiveUser -and $dspm.Count -gt 0) {
                $effectiveUser = [string] $dspm[0].User
            }
            if ($dspm.Count -gt 0 -and -not $startDerivedFromEvidence -and
                $dspm[0].PSObject.Properties.Name -contains 'Happened' -and
                $dspm[0].Happened -and -not $PSBoundParameters.ContainsKey('StartDateUtc') -and -not $ResultPath) {
                $effectiveStart = [datetime] $dspm[0].Happened
            }

            if ($dspm.Count -eq 0 -and -not $dspmError) {
                Write-Warning "No DSPM event exists yet for conversation '$($record.ConversationId)'. DSPM can lag 60 to 90 minutes or longer; wait for logging to update and search again."
            }

            $willSearchAlerts = -not $SkipDlpAlert -and $effectiveUser
            $dlpAlertError = $null
            if ($willSearchAlerts) {
                $alertParameters = @{
                    ConversationId    = [string] $record.ConversationId
                    UserPrincipalName = $effectiveUser
                    StartDateUtc      = $effectiveStart
                    EndDateUtc        = $EndDateUtc
                }
                if ($TenantId) {
                    $alertParameters.TenantId = $TenantId
                }
                if ($UseDeviceCode) {
                    $alertParameters.UseDeviceCode = $true
                }
                $alertParameterSets.Add($alertParameters)
            }
            elseif (-not $SkipDlpAlert) {
                $dlpAlertError = 'A corresponding user could not be derived from unified audit or DSPM data, so DLP alert correlation could not run.'
                Write-Warning "DLP alert lookup couldn't run for conversation '$($record.ConversationId)'. Unified audit or DSPM logging might not be available yet. Wait 60 to 90 minutes and search again."
            }

            $recordStates.Add([pscustomobject]@{
                Record             = $record
                UnifiedAudit       = $unifiedAudit
                UnifiedAuditError  = $unifiedAuditError
                Dspm               = $dspm
                DspmError          = $dspmError
                EffectiveUser      = $effectiveUser
                EffectiveStart     = $effectiveStart
                WillSearchAlerts   = $willSearchAlerts
                DlpAlertError      = $dlpAlertError
            })
        }

        # Phase 2: one isolated Microsoft Graph process handles every queued alert
        # lookup, so a multi-record ResultPath run authenticates to Graph only once.
        $alertsByConversationId = @{}
        $batchAlertError = $null
        if ($alertParameterSets.Count -gt 0) {
            try {
                $batchAlerts = @(Invoke-IsolatedCopilotDlpAlertSearch -ParameterSets $alertParameterSets.ToArray() -ErrorAction Stop)
                foreach ($alert in $batchAlerts) {
                    $key = [string] $alert.ConversationId
                    if (-not $alertsByConversationId.ContainsKey($key)) {
                        $alertsByConversationId[$key] = [Collections.Generic.List[object]]::new()
                    }
                    $alertsByConversationId[$key].Add($alert)
                }
            }
            catch {
                $batchAlertError = $_.Exception.Message
                Write-Warning "DLP alert lookup failed: $batchAlertError"
            }
        }

        # Phase 3: assemble the final evidence object for each record.
        foreach ($state in $recordStates) {
            $record = $state.Record
            $alerts = @()
            $dlpAlertError = $state.DlpAlertError

            if ($state.WillSearchAlerts) {
                if ($batchAlertError) {
                    $dlpAlertError = $batchAlertError
                }
                else {
                    $key = [string] $record.ConversationId
                    if ($alertsByConversationId.ContainsKey($key)) {
                        $alerts = @($alertsByConversationId[$key])
                    }
                }
            }

            if (-not $SkipDlpAlert -and $alerts.Count -eq 0 -and -not $dlpAlertError) {
                Write-Warning "No corresponding DLP alert exists yet for conversation '$($record.ConversationId)'. Alert aggregation and ingestion can be delayed; wait for logging to update and search again."
            }

            [pscustomobject]@{
                PSTypeName          = 'CopilotDlp.Evidence'
                RunId               = $record.RunId
                ConversationId      = $record.ConversationId
                TestUser            = $record.TestUser
                CorrelatedUser      = $state.EffectiveUser
                CorrelatedStartTime = $state.EffectiveStart
                StartedAtUtc        = $record.StartedAtUtc
                UnifiedAuditFound   = $state.UnifiedAudit.Count -gt 0
                DspmEventFound      = $state.Dspm.Count -gt 0
                DlpAlertFound       = $alerts.Count -gt 0
                UnifiedAuditEvents  = $state.UnifiedAudit
                DspmEvents          = $state.Dspm
                DlpAlerts           = $alerts
                UnifiedAuditError   = $state.UnifiedAuditError
                DspmError           = $state.DspmError
                DlpAlertError       = $dlpAlertError
                ValidationRecord    = $record
            }
        }
    }
}

