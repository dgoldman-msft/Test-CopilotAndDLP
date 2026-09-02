function Get-SensitiveTextHash {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Text
    )

    $textBytes = [Text.Encoding]::UTF8.GetBytes($Text)
    [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData($textBytes)
    ).ToLowerInvariant()
}
