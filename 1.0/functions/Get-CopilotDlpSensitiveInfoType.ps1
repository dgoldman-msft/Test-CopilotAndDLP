function Get-CopilotDlpSensitiveInfoType {
    <#
    .SYNOPSIS
    Lists Microsoft Purview built-in sensitive information types (SITs) that
    can be targeted with Test-CopilotAndDLP.

    .DESCRIPTION
    Returns entries from the bundled catalog of built-in sensitive information
    type entity definitions published by Microsoft Learn, so you can find the
    exact name to pass as -SensitiveInfoTypeLabel on Test-CopilotAndDLP, and
    the documentation page describing that type's detection pattern.

    This command only helps you discover the correct name and reference link.
    It does not generate synthetic test values; you must supply a value that
    matches the target type's pattern yourself, approved by your organization.

    .PARAMETER Name
    Filter on the sensitive information type name. Supports wildcards
    (for example, '*passport*'). Defaults to '*' (all types).

    .EXAMPLE
    Get-CopilotDlpSensitiveInfoType -Name '*passport*'

    Lists every bundled sensitive information type with "passport" in its
    name, along with a link to its Microsoft Learn definition page.

    .EXAMPLE
    Get-CopilotDlpSensitiveInfoType -Name 'Credit card number' |
        Select-Object -ExpandProperty DocUrl

    Gets the documentation link for the Credit Card Number sensitive
    information type.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string] $Name = '*'
    )

    Get-SensitiveInfoTypeCatalog | Where-Object { $_.Name -like $Name } | Sort-Object Name
}
