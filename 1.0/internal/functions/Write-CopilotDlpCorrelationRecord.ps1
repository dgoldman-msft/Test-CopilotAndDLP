function Write-CopilotDlpCorrelationRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Collections.IDictionary] $Record,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $parentPath = Split-Path -Parent $Path
    if ($parentPath -and -not (Test-Path -LiteralPath $parentPath)) {
        $null = New-Item -ItemType Directory -Path $parentPath -Force
    }

    $json = $Record | ConvertTo-Json -Compress
    Add-Content -LiteralPath $Path -Value $json -Encoding utf8
}
