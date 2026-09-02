function Search-CopilotDlpAlert {
    <#
    .SYNOPSIS
    Retrieves Microsoft Graph DLP alerts corresponding to a Copilot validation run.

    .DESCRIPTION
    Queries Microsoft Graph security alerts_v2 for Microsoft Data Loss Prevention
    alerts and correlates them with a Test-CopilotAndDLP result by test user and
    activity time window.

    The alerts_v2 response doesn't currently expose the Copilot ConversationId,
    although the Purview DLP alert portal can show it on an associated event.
    Consequently, ConversationId is carried into the output for traceability, but
    the alert match is based on the test user and overlapping activity time. Use
    Search-CopilotDlpAuditEvent for an exact ConversationId match in the unified
    audit record.

    Requires the Microsoft Graph delegated permission SecurityAlert.Read.All and
    a supported Microsoft Entra role such as Security Reader, Global Reader,
    Security Operator, or Security Administrator.

    .PARAMETER ConversationId
    Copilot conversation ID from Test-CopilotAndDLP. Accepts pipeline input by
    property name and is included in the correlation result.

    .PARAMETER UserPrincipalName
    Test account used for the Copilot interaction. Accepts the TestUser property
    from Test-CopilotAndDLP by pipeline input.

    .PARAMETER StartDateUtc
    Start of the Copilot validation run. Accepts the StartedAtUtc property from
    Test-CopilotAndDLP by pipeline input.

    .PARAMETER EndDateUtc
    End of the alert search window. Defaults to the current UTC time.

    .PARAMETER PaddingMinutes
    Number of minutes applied around the activity time when correlating an alert.

    .PARAMETER TenantId
    Microsoft Entra tenant ID or verified tenant domain.

    .PARAMETER UseDeviceCode
    Uses device-code authentication instead of Windows Web Account Manager.
    Without this switch, interactive authentication is used.

    .EXAMPLE
    $result | Search-CopilotDlpAlert

    Retrieves DLP alerts whose user evidence and activity window correspond to a
    Test-CopilotAndDLP validation result.

    .EXAMPLE
    Get-Content './copilot-dlp-results.jsonl' |
        ConvertFrom-Json |
        Search-CopilotDlpAlert -UseDeviceCode

    Reads every saved validation result and correlates each one with Microsoft
    Graph DLP alerts. Multiple interactions can belong to one aggregated alert.

    .EXAMPLE
    Search-CopilotDlpAlert `
        -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
        -UserPrincipalName 'dlp-tester@contoso.example' `
        -StartDateUtc '2026-09-02T15:09:20Z'

    Correlates one known Copilot interaction with a DLP alert by user and
    overlapping activity time. The Graph alert summary doesn't expose the
    ConversationId, so this isn't an exact ID match.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ConversationId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('TestUser')]
        [ValidateNotNullOrEmpty()]
        [string] $UserPrincipalName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('StartedAtUtc')]
        [ValidateNotNullOrEmpty()]
        [datetime] $StartDateUtc = (Get-Date).ToUniversalTime().AddHours(-1),

        [datetime] $EndDateUtc = (Get-Date).ToUniversalTime(),

        [ValidateRange(0, 1440)]
        [int] $PaddingMinutes = 10,

        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string] $TenantId,

        [switch] $UseDeviceCode
    )

    begin {
        Install-RequiredGraphModule -Name 'Microsoft.Graph.Authentication' -LogFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'copilot-dlp-alert-search.log'))

        $graphContext = Get-MgContext -ErrorAction SilentlyContinue
        $hasAlertScope = $graphContext -and $graphContext.Scopes -contains 'SecurityAlert.Read.All'
        $contextTenantId = if ($graphContext -and $graphContext.PSObject.Properties.Name -contains 'TenantId') {
            [string] $graphContext.TenantId
        }
        else {
            $null
        }
        $matchesTenant = -not $TenantId -or $contextTenantId -eq $TenantId

        if ($hasAlertScope -and $matchesTenant) {
            Write-Verbose "Reusing Microsoft Graph connection for $($graphContext.Account)."
        }
        else {
            $connectParameters = @{
                Scopes    = 'SecurityAlert.Read.All'
                NoWelcome = $true
            }
            if ($TenantId) {
                $connectParameters.TenantId = $TenantId
            }
            else {
                # Prevent malformed/default authority errors in device-code flow
                # when no tenant was supplied by the caller.
                $connectParameters.Audience = 'organizations'
            }
            if ($UseDeviceCode) {
                $connectParameters.UseDeviceCode = $true
            }

            try {
                if ($UseDeviceCode) {
                    Write-Information 'Connecting to Microsoft Graph for DLP alerts. Complete the displayed device-code sign-in.' -InformationAction Continue
                    Connect-MgGraph @connectParameters -ErrorAction Stop
                }
                else {
                    $originalConsoleOut = [Console]::Out
                    $originalConsoleError = [Console]::Error
                    $suppressedConsole = [IO.StringWriter]::new()
                    try {
                        [Console]::SetOut($suppressedConsole)
                        [Console]::SetError($suppressedConsole)
                        Connect-MgGraph @connectParameters -ErrorAction Stop *> $null
                    }
                    finally {
                        [Console]::SetOut($originalConsoleOut)
                        [Console]::SetError($originalConsoleError)
                        $suppressedConsole.Dispose()
                    }
                }
            }
            catch {
                $mode = if ($UseDeviceCode) { 'Device-code sign-in failed or was canceled.' } else { 'Interactive Microsoft Graph sign-in failed.' }
                $serviceReason = $_.Exception.Message -replace '(?s)\s+at\s+Microsoft\..*$', ''
                $exception = [InvalidOperationException]::new("Unable to connect to Microsoft Graph for DLP alerts. $mode Action: Retry with -UseDeviceCode and complete sign-in, then verify SecurityAlert.Read.All consent and a supported role such as Security Reader. Service response: $serviceReason")
                $errorRecord = [Management.Automation.ErrorRecord]::new(
                    $exception,
                    'CopilotDlpGraphAuthenticationFailed',
                    [Management.Automation.ErrorCategory]::AuthenticationError,
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }

    process {
        $queryStart = $StartDateUtc.ToUniversalTime().AddMinutes(-1 * $PaddingMinutes).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $queryEnd = $EndDateUtc.ToUniversalTime().AddMinutes($PaddingMinutes).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $filter = "serviceSource eq 'dataLossPrevention' and createdDateTime ge $queryStart and createdDateTime le $queryEnd"
        $uri = 'https://graph.microsoft.com/v1.0/security/alerts_v2?$top=100&$filter=' + [uri]::EscapeDataString($filter)
        $candidateAlertCount = 0
        $matchFound = $false

        Write-Verbose "Searching DLP alerts for conversation $ConversationId, user $UserPrincipalName, and activity time $($StartDateUtc.ToUniversalTime().ToString('o'))."

        do {
            $page = Invoke-MgGraphRequest -Method GET -Uri $uri
            $candidateAlertCount += @($page['value']).Count

            foreach ($alert in @($page['value'])) {
                $alertJson = $alert | ConvertTo-Json -Depth 100 -Compress
                if ($alertJson -notmatch [regex]::Escape($UserPrincipalName)) {
                    continue
                }

                $firstActivity = if ($alert['firstActivityDateTime']) { [datetime] $alert['firstActivityDateTime'] } else { [datetime] $alert['createdDateTime'] }
                $lastActivity = if ($alert['lastActivityDateTime']) { [datetime] $alert['lastActivityDateTime'] } else { [datetime] $alert['createdDateTime'] }
                $paddedFirstActivity = $firstActivity.ToUniversalTime().AddMinutes(-1 * $PaddingMinutes)
                $paddedLastActivity = $lastActivity.ToUniversalTime().AddMinutes($PaddingMinutes)

                if ($StartDateUtc.ToUniversalTime() -lt $paddedFirstActivity -or $StartDateUtc.ToUniversalTime() -gt $paddedLastActivity) {
                    continue
                }

                # additionalData is a nested hashtable; AlertPolicyTitle is far more readable than the alertPolicyId GUID.
                $additionalData = $alert['additionalData']
                $alertPolicyTitle = if ($additionalData -and $additionalData.ContainsKey('AlertPolicyTitle')) {
                    $additionalData['AlertPolicyTitle']
                }
                else {
                    $null
                }

                $matchFound = $true
                [pscustomobject] @{
                    PSTypeName           = 'CopilotDlp.AlertCorrelation'
                    ConversationId       = $ConversationId
                    CorrelationMethod    = 'UserAndActivityWindow'
                    AlertId               = $alert['id']
                    ProviderAlertId       = $alert['providerAlertId']
                    IncidentId            = $alert['incidentId']
                    Title                 = $alert['title']
                    Status                = $alert['status']
                    Severity              = $alert['severity']
                    Classification        = $alert['classification']
                    Determination         = $alert['determination']
                    ServiceSource         = $alert['serviceSource']
                    DetectionSource       = $alert['detectionSource']
                    ProductName           = $alert['productName']
                    AlertPolicyId          = $alert['alertPolicyId']
                    AlertPolicyTitle      = $alertPolicyTitle
                    Category              = $alert['category']
                    Categories            = $alert['categories']
                    Description           = $alert['description']
                    RecommendedActions    = $alert['recommendedActions']
                    InvestigationState    = $alert['investigationState']
                    AssignedTo            = $alert['assignedTo']
                    Comments              = $alert['comments']
                    SystemTags            = $alert['systemTags']
                    DetectorId            = $alert['detectorId']
                    Evidence              = $alert['evidence']
                    CreatedDateTime       = $alert['createdDateTime']
                    LastUpdateDateTime    = $alert['lastUpdateDateTime']
                    ResolvedDateTime      = $alert['resolvedDateTime']
                    FirstActivityDateTime = $alert['firstActivityDateTime']
                    LastActivityDateTime  = $alert['lastActivityDateTime']
                    AlertWebUrl           = $alert['alertWebUrl']
                    IncidentWebUrl        = $alert['incidentWebUrl']
                    Alert                = $alert
                }
            }

            $uri = $page['@odata.nextLink']
        } while ($uri)

        if (-not $matchFound) {
            Write-Warning "No corresponding DLP alert was found for conversation '$ConversationId' and user '$UserPrincipalName' at $($StartDateUtc.ToUniversalTime().ToString('o')). Graph returned $candidateAlertCount DLP alert candidate(s), but none matched both the user and activity window. The alert might not be generated yet, the policy might not create alerts, or this submission might not have matched the DLP rule."
        }
    }
}
