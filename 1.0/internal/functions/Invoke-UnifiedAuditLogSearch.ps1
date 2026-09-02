function Invoke-UnifiedAuditLogSearch {
    <#
    .SYNOPSIS
    Thin wrapper around Search-UnifiedAuditLog for testability.

    .DESCRIPTION
    Search-UnifiedAuditLog is a proxy cmdlet that ExchangeOnlineManagement adds
    dynamically only after Connect-ExchangeOnline succeeds, so it doesn't exist
    as a mockable command until a live connection is made. This wrapper always
    exists in module scope, so tests can mock it directly instead of the proxy
    cmdlet.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RecordType,

        [Parameter(Mandatory)]
        [string] $UserIds,

        [Parameter(Mandatory)]
        [datetime] $StartDate,

        [Parameter(Mandatory)]
        [datetime] $EndDate,

        [Parameter(Mandatory)]
        [int] $ResultSize
    )

    Search-UnifiedAuditLog `
        -RecordType $RecordType `
        -UserIds $UserIds `
        -StartDate $StartDate `
        -EndDate $EndDate `
        -ResultSize $ResultSize
}
