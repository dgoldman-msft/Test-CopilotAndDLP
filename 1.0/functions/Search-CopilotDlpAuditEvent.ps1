function Search-CopilotDlpAuditEvent {
    <#
    .SYNOPSIS
    Searches the Microsoft Purview unified audit log for Copilot interaction
    records that may correspond to a Test-CopilotAndDLP run.

    .DESCRIPTION
    Queries the unified audit log (RecordType CopilotInteraction) for a user
    and time window, so you can correlate a Test-CopilotAndDLP run with the
    Microsoft Purview audit trail. A returned record confirms that a Copilot
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

    .PARAMETER UserPrincipalName
    The signed-in test account to search for. Accepts the TestUser property
    from a Test-CopilotAndDLP result object by pipeline binding.

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

    .PARAMETER ResultSize
    Maximum number of unified audit log records to return. Defaults to 100.

    .EXAMPLE
    Search-CopilotDlpAuditEvent -UserPrincipalName 'dlp-tester@contoso.example' `
        -StartDateUtc (Get-Date).AddHours(-2)

    Searches the last two hours of CopilotInteraction audit records for the
    specified test account.

    .EXAMPLE
    $result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
    $result | Search-CopilotDlpAuditEvent

    Pipes a Test-CopilotAndDLP result directly into the audit search using
    its TestUser and StartedAtUtc properties.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('TestUser')]
        [ValidateNotNullOrEmpty()]
        [string] $UserPrincipalName,

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

        [ValidateRange(1, 5000)]
        [int] $ResultSize = 100
    )

    process {
        Install-RequiredGraphModule -Name 'ExchangeOnlineManagement' -LogFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'copilot-dlp-audit-search.log'))

        $connectParameters = @{ ShowBanner = $false }
        if ($TenantId) {
            $connectParameters.Organization = $TenantId
        }
        Connect-ExchangeOnline @connectParameters

        $paddedStart = $StartDateUtc.AddMinutes(-1 * $PaddingMinutes)
        $paddedEnd = $EndDateUtc.AddMinutes($PaddingMinutes)

        Write-Verbose "Searching CopilotInteraction audit records for $UserPrincipalName between $paddedStart and $paddedEnd (UTC)."

        $records = Invoke-UnifiedAuditLogSearch `
            -RecordType 'CopilotInteraction' `
            -UserIds $UserPrincipalName `
            -StartDate $paddedStart `
            -EndDate $paddedEnd `
            -ResultSize $ResultSize

        foreach ($record in $records) {
            $auditData = $record.AuditData | ConvertFrom-Json

            [pscustomobject] @{
                PSTypeName   = 'CopilotDlp.AuditEvent'
                CreationTime = $record.CreationDate
                UserId       = $record.UserIds
                Operation    = $record.Operations
                RecordType   = $record.RecordType
                Workload     = $auditData.Workload
                AppHost      = $auditData.AppHost
                AuditData    = $auditData
            }
        }
    }
}
