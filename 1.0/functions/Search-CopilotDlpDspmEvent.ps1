function Search-CopilotDlpDspmEvent {
    <#
    .SYNOPSIS
    Searches DSPM Activity Explorer for a Copilot DLP conversation.

    .DESCRIPTION
    Queries Microsoft Purview Activity Explorer through
    Export-ActivityExplorerData and returns Copilot and DLP events whose JSON
    payload contains the exact ConversationId. The command supports one
    conversation, pipeline input, or every record in a Test-CopilotAndDLP JSONL
    result file.

    Activity Explorer can lag unified audit by 60 to 90 minutes or longer and
    reports only the last 30 days. This command requires Security & Compliance
    PowerShell permissions for Activity Explorer. It reuses an existing session
    when Export-ActivityExplorerData is available in the current process. When no
    reusable session exists, it calls Connect-IPPSSession. Console and PowerShell
    streams are isolated during connection so affected ExchangeOnlineManagement
    versions can't expose an internal MSAL call stack to the end user. When a row
    has a nested CopilotEventData.ConversationId, that exact value is used for
    matching; otherwise the command falls back to a substring search of the
    serialized row.

    Output fields verified against a real "Copilot Interaction" row for the
    PurviewForAI data platform include RecordIdentity, ActivityId,
    AppLocation, AppHost, DataPlatform, ClientIP, AppIdentity,
    AppIdentityCategory, AppIdentityGroup, UserType, LicenseType, ThreadId,
    DLPEvaluationDeferred, MemoryUpdated, Messages (message IDs and
    isPrompt/JailbreakDetected flags only, not prompt or response text),
    AISystemPlugin (Name/Id pairs), HasWebsearchQuery, AreFilesReferenced,
    AreSensitiveFilesReferenced, and SensitivityLabelIdsReferenced.
    Activity Explorer does not expose raw prompt or response text through this
    API. Field availability can vary by tenant, activity type, and Purview
    portal version; every field is returned as null when absent rather than
    causing an error.

    .PARAMETER ConversationId
    Copilot conversation ID to match exactly in DSPM event data.

    .PARAMETER UserPrincipalName
    Optional test user used to further constrain matching DSPM records.

    .PARAMETER ResultPath
    Path to a Test-CopilotAndDLP JSONL result file. Every record is searched. When
    called directly (not from the pipeline) with no -ConversationId,
    -UserPrincipalName, or -ResultPath, the command looks for
    copilot-dlp-results.jsonl in the current directory and uses it automatically;
    if that file doesn't exist, it throws asking for -ConversationId.

    .PARAMETER StartDateUtc
    Start of the DSPM search window. Accepts StartedAtUtc by property name.

    .PARAMETER EndDateUtc
    End of the DSPM search window. Defaults to the current UTC time.
    Values in the future are clamped to the current time because Activity Explorer rejects
    future dates.

    .PARAMETER PaddingMinutes
    Minutes added around the validation time. Defaults to 60.

    .PARAMETER TenantId
    Microsoft Entra tenant ID or verified tenant domain.

    .PARAMETER ConversationIdLookbackDays
    When -ConversationId is supplied directly with no -StartDateUtc, and that
    conversation isn't in the default copilot-dlp-results.jsonl file, how many
    days to look back instead of the usual two-hour default. Applies to
    ConversationId values obtained from the Purview alerts portal rather than a
    saved run. Defaults to 7.

    .EXAMPLE
    Search-CopilotDlpDspmEvent `
        -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
        -StartDateUtc '2026-09-02T15:00:00Z'

    Returns Activity Explorer records containing the exact conversation ID.

    .EXAMPLE
    Search-CopilotDlpDspmEvent -ResultPath './copilot-dlp-results.jsonl'

    Searches every saved validation record using one compliance connection.

    .EXAMPLE
    Search-CopilotDlpDspmEvent

    Called with no arguments in the directory containing copilot-dlp-results.jsonl,
    searches every record in that file automatically.

    .EXAMPLE
    Search-CopilotDlpDspmEvent -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5'

    A ConversationId copied from the Purview alerts portal's Correlation ID field,
    with no -StartDateUtc supplied. The command looks it up in
    copilot-dlp-results.jsonl first; if it isn't there, it searches the last 7
    days instead of the usual two-hour default.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
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

        [ValidateRange(0, 1440)]
        [int] $PaddingMinutes = 60,

        [string] $TenantId,

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

        Install-RequiredGraphModule `
            -Name 'ExchangeOnlineManagement' `
            -MinimumVersion '3.10.1' `
            -LogFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'copilot-dlp-dspm-search.log'))

        $activityExplorerCommand = Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue
        if (-not $activityExplorerCommand) {
            $connectParameters = @{ ShowBanner = $false }
            if ($TenantId) {
                $connectParameters.Organization = $TenantId
            }
            if ($IsWindows) {
                $connectParameters.DisableWAM = $true
            }

            $originalConsoleOut = [Console]::Out
            $originalConsoleError = [Console]::Error
            $suppressedConsole = [IO.StringWriter]::new()
            $connectionError = $null

            Write-Information 'Connecting to Security & Compliance PowerShell for DSPM Activity Explorer. Complete the sign-in window if prompted.' -InformationAction Continue
            try {
                [Console]::SetOut($suppressedConsole)
                [Console]::SetError($suppressedConsole)
                Connect-IPPSSession @connectParameters -ErrorAction Stop *> $null
            }
            catch {
                $connectionError = $_.Exception.Message
            }
            finally {
                [Console]::SetOut($originalConsoleOut)
                [Console]::SetError($originalConsoleError)
                $suppressedConsole.Dispose()
            }

            $activityExplorerCommand = Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue
            if ($connectionError -or -not $activityExplorerCommand) {
                $exception = [InvalidOperationException]::new(
                    'Unable to connect to Security & Compliance PowerShell for DSPM Activity Explorer. Action: Close this PowerShell terminal, open a new PowerShell 7 terminal so the updated ExchangeOnlineManagement assembly can load, import the module again, and retry. Then verify an Activity Explorer role such as Security Reader, Compliance Administrator, or Information Protection Reader.'
                )
                $errorRecord = [Management.Automation.ErrorRecord]::new(
                    $exception,
                    'CopilotDlpDspmAuthenticationFailed',
                    [Management.Automation.ErrorCategory]::AuthenticationError,
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
        else {
            Write-Verbose 'Reusing the current Security & Compliance PowerShell session for DSPM Activity Explorer.'
        }
    }

    process {
        if ($ResultPath -and ($ConversationId -or $UserPrincipalName)) {
            throw "Use -ResultPath by itself; don't combine it with -ConversationId or -UserPrincipalName."
        }

        $validationRecords = if ($ResultPath) {
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

        foreach ($validationRecord in $validationRecords) {
            $targetConversationId = [string] $validationRecord.ConversationId
            if ([string]::IsNullOrWhiteSpace($targetConversationId)) {
                throw 'A ConversationId is required directly, through pipeline input, or in each ResultPath record.'
            }

            $targetUser = [string] $validationRecord.TestUser
            $targetStart = if ($validationRecord.StartedAtUtc) { [datetime] $validationRecord.StartedAtUtc } else { $StartDateUtc }
            $searchStart = $targetStart.ToUniversalTime().AddMinutes(-1 * $PaddingMinutes)
            $nowUtc = [datetime]::UtcNow
            # Export-ActivityExplorerData rejects end times too close to the real current
            # moment (clock skew / eventual consistency), so clamp a few minutes short of "now".
            $safeNowUtc = $nowUtc.AddMinutes(-5)
            $oldestAllowedUtc = $nowUtc.AddDays(-30).AddMinutes(5)
            $searchEnd = $EndDateUtc.ToUniversalTime().AddMinutes($PaddingMinutes)
            if ($searchStart -lt $oldestAllowedUtc) {
                $searchStart = $oldestAllowedUtc
            }
            if ($searchEnd -gt $safeNowUtc) {
                $searchEnd = $safeNowUtc
            }
            if ($searchStart -gt $searchEnd) {
                throw "The DSPM search start time '$searchStart' is after the allowed end time '$searchEnd'. Action: Supply a StartDateUtc within the last 30 days and not in the future."
            }
            $pageCookie = $null
            $matchCount = 0

            Write-Verbose "Searching DSPM Activity Explorer for conversation $targetConversationId between $searchStart and $searchEnd (UTC)."

            do {
                try {
                    $page = Invoke-ActivityExplorerExport -StartTime $searchStart -EndTime $searchEnd -PageCookie $pageCookie -ErrorAction Stop
                }
                catch {
                    throw "DSPM Activity Explorer query failed. Action: Verify the date is within the last 30 days, confirm Activity Explorer permissions, and retry. Service response: $($_.Exception.Message)"
                }

                if (-not $page -or $page.PSObject.Properties.Name -notcontains 'ResultData') {
                    throw 'DSPM Activity Explorer returned no result data. Action: Wait for Activity Explorer ingestion, confirm permissions, and retry.'
                }

                $rows = if ($page.ResultData -is [string]) { @($page.ResultData | ConvertFrom-Json) } else { @($page.ResultData) }

                foreach ($row in $rows) {
                    $copilotEventData = if ($row.PSObject.Properties.Name -contains 'CopilotEventData') { $row.CopilotEventData } else { $null }
                    $nestedConversationId = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'ConversationId') { [string] $copilotEventData.ConversationId } else { $null }

                    if ($nestedConversationId) {
                        # CopilotEventData.ConversationId is an exact, verified field; prefer it over a substring search.
                        if (-not $nestedConversationId.Equals($targetConversationId, [StringComparison]::OrdinalIgnoreCase)) {
                            continue
                        }
                    }
                    else {
                        $rowJson = $row | ConvertTo-Json -Depth 100 -Compress
                        if ($rowJson -notmatch [regex]::Escape($targetConversationId)) {
                            continue
                        }
                    }
                    if ($targetUser -and [string] $row.User -ne $targetUser -and ($row | ConvertTo-Json -Depth 100 -Compress) -notmatch [regex]::Escape($targetUser)) {
                        continue
                    }

                    $rowProperties = $row.PSObject.Properties.Name
                    $activity = if ($rowProperties -contains 'Activity') { $row.Activity } else { $null }
                    $happened = if ($rowProperties -contains 'Happened') { $row.Happened } else { $null }
                    $user = if ($rowProperties -contains 'User') { $row.User } else { $null }
                    $workload = if ($rowProperties -contains 'Workload') { $row.Workload } else { $null }

                    # Verified against a real Export-ActivityExplorerData "Copilot Interaction" row for the "PurviewForAI" data platform.
                    # Other activity types (for example a DLP rule-match row) may expose a different shape; unknown fields stay null.
                    $recordIdentity = if ($rowProperties -contains 'RecordIdentity') { $row.RecordIdentity } else { $null }
                    $activityId = if ($rowProperties -contains 'ActivityId') { $row.ActivityId } else { $null }
                    $appLocation = if ($rowProperties -contains 'PurviewAIAppLocation') { $row.PurviewAIAppLocation } else { $null }
                    $dataPlatform = if ($rowProperties -contains 'DataPlatform') { $row.DataPlatform } else { $null }
                    $clientIP = if ($rowProperties -contains 'ClientIP') { $row.ClientIP } else { $null }
                    $appIdentity = if ($rowProperties -contains 'AppIdentity') { $row.AppIdentity } else { $null }
                    $appIdentityCategory = if ($rowProperties -contains 'AppIdentityCategory') { $row.AppIdentityCategory } else { $null }
                    $appIdentityGroup = if ($rowProperties -contains 'AppIdentityGroup') { $row.AppIdentityGroup } else { $null }
                    $userType = if ($rowProperties -contains 'UserType') { $row.UserType } else { $null }
                    $licenseType = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'LicenseType') { $copilotEventData.LicenseType } else { $null }
                    $threadId = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'ThreadId') { $copilotEventData.ThreadId } else { $null }
                    $appHost = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'AppHost') { $copilotEventData.AppHost } else { $null }
                    $dlpEvaluationDeferred = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'DLPEvaluationDeferred') { $copilotEventData.DLPEvaluationDeferred } else { $null }
                    $memoryUpdated = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'MemoryUpdated') { $copilotEventData.MemoryUpdated } else { $null }
                    $messages = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'Messages') { , @($copilotEventData.Messages) } else { $null }
                    $aiSystemPlugins = if ($copilotEventData -and $copilotEventData.PSObject.Properties.Name -contains 'AISystemPlugin') { , @($copilotEventData.AISystemPlugin) } else { $null }
                    $hasWebSearchQuery = if ($rowProperties -contains 'HasWebsearchQuery') { $row.HasWebsearchQuery } else { $null }
                    $areFilesReferenced = if ($rowProperties -contains 'AreFilesReferenced') { $row.AreFilesReferenced } else { $null }
                    $areSensitiveFilesReferenced = if ($rowProperties -contains 'AreSensitiveFilesReferenced') { $row.AreSensitiveFilesReferenced } else { $null }
                    $sensitivityLabelIdsReferenced = if ($rowProperties -contains 'SensitivityLabelIdsReferenced') { , @($row.SensitivityLabelIdsReferenced) } else { $null }

                    $matchCount++
                    [pscustomobject]@{
                        PSTypeName                     = 'CopilotDlp.DspmEvent'
                        Source                         = 'DSPMActivityExplorer'
                        RunId                          = $validationRecord.RunId
                        ConversationId                  = if ($nestedConversationId) { $nestedConversationId } else { $targetConversationId }
                        Activity                       = $activity
                        ActivityId                     = $activityId
                        Happened                       = $happened
                        User                           = $user
                        Workload                       = $workload
                        RecordIdentity                 = $recordIdentity
                        AppLocation                    = $appLocation
                        AppHost                        = $appHost
                        DataPlatform                   = $dataPlatform
                        ClientIP                       = $clientIP
                        AppIdentity                    = $appIdentity
                        AppIdentityCategory            = $appIdentityCategory
                        AppIdentityGroup               = $appIdentityGroup
                        UserType                       = $userType
                        LicenseType                    = $licenseType
                        ThreadId                       = $threadId
                        DLPEvaluationDeferred          = $dlpEvaluationDeferred
                        MemoryUpdated                  = $memoryUpdated
                        Messages                       = $messages
                        AISystemPlugin                 = $aiSystemPlugins
                        HasWebsearchQuery              = $hasWebSearchQuery
                        AreFilesReferenced             = $areFilesReferenced
                        AreSensitiveFilesReferenced    = $areSensitiveFilesReferenced
                        SensitivityLabelIdsReferenced  = $sensitivityLabelIdsReferenced
                        ValidationRecord               = $validationRecord
                        DspmData                       = $row
                    }
                }

                $pageCookie = if ($page.PSObject.Properties.Name -contains 'LastPage' -and $page.LastPage -eq $false) {
                    [string] $page.WaterMark
                }
                else {
                    $null
                }
            } while ($pageCookie)

            if ($matchCount -eq 0) {
                Write-Warning "No DSPM Activity Explorer event was found for conversation '$targetConversationId'. Activity Explorer can lag 60 to 90 minutes or longer; retry later and confirm the account has Activity Explorer permissions."
            }
        }
    }
}
