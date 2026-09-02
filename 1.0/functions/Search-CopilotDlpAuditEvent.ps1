function Search-CopilotDlpAuditEvent {
    <#
    .SYNOPSIS
    Searches the Microsoft Purview unified audit log for Copilot interaction
    records that may correspond to a Test-CopilotAndDLP run.

    .DESCRIPTION
    Queries the unified audit log (RecordType CopilotInteraction) for a
    conversation ID, user, and time window, so you can correlate a
    Test-CopilotAndDLP run with the Microsoft Purview audit trail. A returned record confirms that a Copilot
    interaction was audited for that user in that window; it does not by
    itself confirm which DLP policy (if any) matched the prompt.

    Audit log ingestion can lag by 30 minutes or more after the interaction
    occurred. If no records are found, wait and run the search again.

    For the actual sensitive-information-type matches and prompt text
    detected for an interaction, use the Activity explorer in Data Security
    Posture Management (DSPM) for AI, or Content Search, in the Microsoft
    Purview portal. For a DLP policy match that is configured to generate an
    alert, check Alerts in the Microsoft Purview portal or query the
    Microsoft Graph Security API (alerts_v2).

    This command requires the ExchangeOnlineManagement module and a role
    with unified audit log read permissions (for example, View-Only Audit
    Logs or Audit Logs) in Microsoft Purview or Exchange Online.

    If the current PowerShell process already has an active Exchange Online
    connection with a valid token, the command reuses it and doesn't prompt
    for authentication. Connections are process-scoped; a connection in a
    different terminal or PowerShell process can't be reused.

    .PARAMETER UserPrincipalName
    The signed-in test account used to narrow the search. Accepts the TestUser
    property from a Test-CopilotAndDLP result object by pipeline binding. Either
    UserPrincipalName or ConversationId must be supplied.

    .PARAMETER ConversationId
    The Copilot conversation ID to match exactly in the JSON audit payload.
    Accepts the ConversationId property from a Test-CopilotAndDLP result object
    by pipeline binding. Either ConversationId or UserPrincipalName must be supplied.

    .PARAMETER ResultPath
    Path to a Test-CopilotAndDLP JSONL result file. The command reads every
    validation record, searches each ConversationId, and returns the submission
    metadata together with the corresponding complete unified audit record. When
    called directly (not from the pipeline) with no -ConversationId,
    -UserPrincipalName, or -ResultPath, the command looks for
    copilot-dlp-results.jsonl in the current directory and uses it automatically;
    if that file doesn't exist, it throws asking for -ConversationId.

    .PARAMETER StartDateUtc
    Start of the search window in UTC. Accepts the StartedAtUtc property
    from a Test-CopilotAndDLP result object by pipeline binding.

    .PARAMETER EndDateUtc
    End of the search window in UTC. Defaults to the current time.

    .PARAMETER PaddingMinutes
    Minutes to subtract from StartDateUtc and add to EndDateUtc, to allow for
    clock skew and audit log processing delay.

    .PARAMETER TenantId
    Microsoft Entra tenant ID or verified tenant domain for the Exchange
    Online connection. When omitted, interactive sign-in determines the
    tenant.

    .PARAMETER UseDeviceCode
    Uses Exchange Online device-code authentication. Without this switch, the
    command uses interactive authentication and passes UserPrincipalName as the
    account hint. UserPrincipalName identifies the account but isn't a credential
    or token, so authentication can still be required when no connection exists.

    .PARAMETER ResultSize
    Maximum number of unified audit log records to return. Defaults to 100.

    .PARAMETER PollForMatch
    Retries the search on a backoff schedule until a matching audit record
    appears or -PollTimeoutMinutes elapses, instead of a single search attempt.
    Useful because audit ingestion can lag by 30 minutes or more. Can't be
    combined with -ResultPath.

    .PARAMETER PollIntervalSeconds
    Delay before the first retry when -PollForMatch is set. Doubles after each
    unsuccessful attempt, up to 5 minutes. Defaults to 60.

    .PARAMETER PollTimeoutMinutes
    Maximum time to keep retrying when -PollForMatch is set before giving up
    and writing a warning. Use 0 to make a single attempt. Defaults to 30.

    .PARAMETER ConversationIdLookbackDays
    When -ConversationId is supplied directly with no -StartDateUtc, and that
    conversation isn't in the default copilot-dlp-results.jsonl file, how many
    days to look back instead of the usual one-hour default. Applies to
    ConversationId values obtained from the Purview alerts portal rather than a
    saved run. Defaults to 7.

    .EXAMPLE
    Search-CopilotDlpAuditEvent -UserPrincipalName 'dlp-tester@contoso.example' `
        -StartDateUtc (Get-Date).AddHours(-2)

    Searches the last two hours of CopilotInteraction audit records for the
    specified test account.

    .EXAMPLE
    $result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
    $result | Search-CopilotDlpAuditEvent

    Pipes a Test-CopilotAndDLP result directly into the audit search using its
    ConversationId, TestUser, and StartedAtUtc properties. Only an audit record
    containing that exact conversation ID is returned.

    .EXAMPLE
    Search-CopilotDlpAuditEvent `
        -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
        -StartDateUtc (Get-Date).AddHours(-2)

    Searches for a CopilotInteraction record with an exact conversation ID.

    .EXAMPLE
    Search-CopilotDlpAuditEvent `
        -ResultPath './copilot-dlp-results.jsonl' `
        -UseDeviceCode

    Reads every validation result in the JSONL file and returns the corresponding
    unified audit information for each ConversationId.

    .EXAMPLE
    $result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
    $result | Search-CopilotDlpAuditEvent -PollForMatch -PollTimeoutMinutes 45

    Polls on a backoff schedule for up to 45 minutes until the matching
    CopilotInteraction audit record appears, instead of a single search attempt.

    .EXAMPLE
    Search-CopilotDlpAuditEvent

    Called with no arguments in the directory containing copilot-dlp-results.jsonl,
    searches every record in that file automatically.

    .EXAMPLE
    Search-CopilotDlpAuditEvent -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5'

    A ConversationId copied from the Purview alerts portal's Correlation ID field,
    with no -StartDateUtc supplied. The command looks it up in
    copilot-dlp-results.jsonl first; if it isn't there, it searches the last 7
    days instead of the usual one-hour default.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('TestUser')]
        [ValidateNotNullOrEmpty()]
        [string] $UserPrincipalName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ConversationId,

        [Alias('Path')]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string] $ResultPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('StartedAtUtc')]
        [ValidateNotNullOrEmpty()]
        [datetime] $StartDateUtc = (Get-Date).ToUniversalTime().AddHours(-1),

        [ValidateNotNullOrEmpty()]
        [datetime] $EndDateUtc = (Get-Date).ToUniversalTime(),

        [ValidateRange(0, 1440)]
        [int] $PaddingMinutes = 60,

        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string] $TenantId,

        [switch] $UseDeviceCode,

        [ValidateRange(1, 5000)]
        [int] $ResultSize = 100,

        [switch] $PollForMatch,

        [ValidateRange(5, 3600)]
        [int] $PollIntervalSeconds = 60,

        [ValidateRange(0, 1440)]
        [int] $PollTimeoutMinutes = 30,

        [ValidateRange(1, 90)]
        [int] $ConversationIdLookbackDays = 7
    )

    begin {
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

        Install-RequiredGraphModule -Name 'ExchangeOnlineManagement' -LogFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'copilot-dlp-audit-search.log'))

        $activeConnections = @(
            Get-ExchangeConnectionInformation | Where-Object {
                $isConnected = [string] $_.State -eq 'Connected'
                $hasActiveToken = $_.PSObject.Properties.Name -notcontains 'TokenStatus' -or [string] $_.TokenStatus -eq 'Active'
                $matchesTenant = -not $TenantId -or [string] $_.TenantID -eq $TenantId
                $isConnected -and $hasActiveToken -and $matchesTenant
            }
        )

        if ($activeConnections.Count -gt 0) {
            $activeConnection = $activeConnections | Select-Object -First 1
            Write-Verbose "Reusing active Exchange Online connection $($activeConnection.ConnectionId) for $($activeConnection.UserPrincipalName)."
        }
        else {
            $connectParameters = @{ ShowBanner = $false }
            if ($TenantId) {
                $connectParameters.Organization = $TenantId
            }
            if ($UserPrincipalName) {
                $connectParameters.UserPrincipalName = $UserPrincipalName
            }
            if ($UseDeviceCode) {
                $connectParameters.Device = $true
            }
            try {
                if ($UseDeviceCode) {
                    Write-Information 'Connecting to Exchange Online for unified audit search. Complete the displayed device-code sign-in.' -InformationAction Continue
                    Connect-ExchangeOnline @connectParameters -ErrorAction Stop
                }
                else {
                    $originalConsoleOut = [Console]::Out
                    $originalConsoleError = [Console]::Error
                    $suppressedConsole = [IO.StringWriter]::new()
                    try {
                        [Console]::SetOut($suppressedConsole)
                        [Console]::SetError($suppressedConsole)
                        Connect-ExchangeOnline @connectParameters -ErrorAction Stop *> $null
                    }
                    finally {
                        [Console]::SetOut($originalConsoleOut)
                        [Console]::SetError($originalConsoleError)
                        $suppressedConsole.Dispose()
                    }
                }
            }
            catch {
                $nextStep = if ($UseDeviceCode) {
                    'Device-code authentication failed or was canceled. Run the command again and complete the browser sign-in promptly. If it continues to fail, verify Conditional Access and your Purview audit-log role.'
                }
                else {
                    'The default Exchange Online sign-in failed. Run the command again with -UseDeviceCode and complete the browser sign-in.'
                }

                $exception = [System.InvalidOperationException]::new("Unable to connect to Exchange Online. $nextStep")
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'CopilotDlpExchangeAuthenticationFailed',
                    [System.Management.Automation.ErrorCategory]::AuthenticationError,
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }

    process {
        if ($ResultPath -and ($ConversationId -or $UserPrincipalName)) {
            throw "Use -ResultPath by itself; don't combine it with -ConversationId or -UserPrincipalName."
        }
        if ($ResultPath -and $PollForMatch) {
            throw "-PollForMatch can't be combined with -ResultPath. Poll a single conversation with -ConversationId, -UserPrincipalName, or pipeline input instead."
        }

        $validationRecords = if ($ResultPath) {
            @(Get-Content -LiteralPath $ResultPath | ConvertFrom-Json)
        }
        else {
            @([pscustomobject] @{
                RunId              = $null
                ConversationId     = $ConversationId
                TestUser           = $UserPrincipalName
                StartedAtUtc       = $StartDateUtc
                SubmissionStatus   = $null
                ExpectedDlpOutcome = $null
            })
        }

        if ($validationRecords.Count -eq 0) {
            Write-Warning "No validation records were found in '$ResultPath'."
            return
        }

        foreach ($validationRecord in $validationRecords) {
            $targetConversationId = [string] $validationRecord.ConversationId
            $targetUser = [string] $validationRecord.TestUser
            $targetStartDate = if ($validationRecord.StartedAtUtc) {
                [datetime] $validationRecord.StartedAtUtc
            }
            else {
                $StartDateUtc
            }

            if ([string]::IsNullOrWhiteSpace($targetUser) -and [string]::IsNullOrWhiteSpace($targetConversationId)) {
                throw 'Specify -ConversationId, -UserPrincipalName, or -ResultPath containing those properties.'
            }

            $searchTarget = if ($targetConversationId) { "conversation $targetConversationId" } else { "user $targetUser" }
            $pollDeadline = [datetime]::UtcNow.AddMinutes($PollTimeoutMinutes)
            $pollDelaySeconds = $PollIntervalSeconds
            $attempt = 0
            $matchFound = $false

            do {
                $attempt++
                $paddedStart = $targetStartDate.AddMinutes(-1 * $PaddingMinutes)
                $paddedEnd = ([datetime]::UtcNow).AddMinutes($PaddingMinutes)
                if ($paddedEnd -gt $EndDateUtc.AddMinutes($PaddingMinutes)) {
                    $paddedEnd = $EndDateUtc.AddMinutes($PaddingMinutes)
                }

                Write-Verbose "Searching CopilotInteraction audit records for $searchTarget between $paddedStart and $paddedEnd (UTC), attempt $attempt."

                $searchParameters = @{
                    RecordType = 'CopilotInteraction'
                    StartDate  = $paddedStart
                    EndDate    = $paddedEnd
                    ResultSize = $ResultSize
                }
                if ($targetUser) {
                    $searchParameters.UserIds = $targetUser
                }
                if ($targetConversationId) {
                    $searchParameters.FreeText = $targetConversationId
                }

                $records = Invoke-UnifiedAuditLogSearch @searchParameters

                foreach ($record in $records) {
                    $auditData = $record.AuditData | ConvertFrom-Json
                    $copilotEventData = if ($auditData.PSObject.Properties.Name -contains 'CopilotEventData') {
                        $auditData.CopilotEventData
                    }
                    else {
                        $auditData
                    }
                    $recordConversationId = [string] $copilotEventData.ConversationId
                    $dlpEvaluationDeferred = if ($copilotEventData.PSObject.Properties.Name -contains 'DLPEvaluationDeferred') {
                        $copilotEventData.DLPEvaluationDeferred
                    }
                    else {
                        $null
                    }
                    $dlpEvaluationDeferredReason = if ($copilotEventData.PSObject.Properties.Name -contains 'DLPEvaluationDeferredReason') {
                        $copilotEventData.DLPEvaluationDeferredReason
                    }
                    else {
                        $null
                    }

                    if ($targetConversationId -and -not $recordConversationId.Equals($targetConversationId, [StringComparison]::OrdinalIgnoreCase)) {
                        continue
                    }

                    # Search-UnifiedAuditLog returns CreationDate already numerically in UTC but tagged Local/Unspecified;
                    # re-tag without shifting the value, so downstream .ToUniversalTime() calls don't double-convert it.
                    $creationTime = if ($record.CreationDate -is [datetime]) {
                        [DateTime]::SpecifyKind($record.CreationDate, [DateTimeKind]::Utc)
                    }
                    else {
                        $record.CreationDate
                    }

                    $matchFound = $true
                    [pscustomobject] @{
                        PSTypeName                 = 'CopilotDlp.AuditEvent'
                        RunId                      = $validationRecord.RunId
                        ConversationId             = $recordConversationId
                        SubmissionStatus           = $validationRecord.SubmissionStatus
                        ExpectedDlpOutcome          = $validationRecord.ExpectedDlpOutcome
                        CreationTime               = $creationTime
                        UserId                     = $record.UserIds
                        Operation                  = $record.Operations
                        RecordType                 = $record.RecordType
                        Workload                   = $auditData.Workload
                        AppHost                    = $copilotEventData.AppHost
                        DLPEvaluationDeferred       = $dlpEvaluationDeferred
                        DLPEvaluationDeferredReason = $dlpEvaluationDeferredReason
                        ValidationRecord            = $validationRecord
                        AuditData                  = $auditData
                    }
                }

                if ($matchFound) {
                    break
                }

                if (-not $PollForMatch) {
                    Write-Warning "No matching CopilotInteraction record appeared for $searchTarget between $paddedStart and $paddedEnd (UTC). If the actual activity happened outside this window, pass -StartDateUtc/-EndDateUtc to widen it, use -PollForMatch to retry automatically, or use -ResultPath/pipeline input so the activity time is read from the saved run."
                    break
                }

                if ([datetime]::UtcNow -ge $pollDeadline) {
                    Write-Warning "No matching CopilotInteraction record appeared for $searchTarget within $PollTimeoutMinutes minute(s). Audit ingestion can lag further; run the search again later."
                    break
                }

                Write-Verbose "No match yet for $searchTarget on attempt $attempt. Waiting $pollDelaySeconds second(s) before retrying."
                Start-Sleep -Seconds $pollDelaySeconds
                $pollDelaySeconds = [Math]::Min($pollDelaySeconds * 2, 300)
            } while ($true)
        }
    }
}

