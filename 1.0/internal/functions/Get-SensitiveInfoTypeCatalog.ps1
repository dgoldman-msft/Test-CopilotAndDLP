function Get-SensitiveInfoTypeCatalog {
    <#
    .SYNOPSIS
    Loads the bundled Microsoft Purview sensitive information type catalog.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $catalogPath = Join-Path $script:CopilotDlpModuleRoot 'data\SensitiveInfoTypes.psd1'
    $catalog = Import-PowerShellDataFile -Path $catalogPath

    foreach ($entry in $catalog.Entries) {
        [pscustomobject] @{
            PSTypeName = 'CopilotDlp.SensitiveInfoType'
            Name       = $entry.Name
            DocUrl     = "https://learn.microsoft.com/en-us/purview/$($entry.DocSlug)"
        }
    }
}
