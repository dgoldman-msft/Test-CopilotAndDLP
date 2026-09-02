function Invoke-IsolatedCopilotDlpAlertSearch {
    <#
    .SYNOPSIS
    Runs Graph DLP alert correlation in an isolated PowerShell process.

    .DESCRIPTION
    ExchangeOnlineManagement and Microsoft.Graph.Authentication can load
    incompatible Microsoft.Identity.Client assembly versions. Process isolation
    prevents those dependencies from colliding during combined evidence searches.

    All parameter sets are processed in one child process so only one Microsoft
    Graph connection is established, even when Search-CopilotDlpAndDspmEvidence is
    correlating many conversations from a JSONL file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable[]] $ParameterSets
    )

    $temporaryResultPath = Join-Path ([IO.Path]::GetTempPath()) "copilot-dlp-alert-$([guid]::NewGuid()).clixml"
    $manifestPath = Join-Path $script:CopilotDlpModuleRoot 'Test-CopilotAndDLP.psd1'
    $parameterJson = $ParameterSets | ConvertTo-Json -Depth 10 -Compress
    $parameterBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($parameterJson))

    $childScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$($manifestPath.Replace("'", "''"))' -Force
`$json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$parameterBase64'))
`$parameterSets = @(`$json | ConvertFrom-Json -AsHashtable)
`$results = foreach (`$parameterSet in `$parameterSets) { Search-CopilotDlpAlert @parameterSet }
@(`$results) | Export-Clixml -LiteralPath '$($temporaryResultPath.Replace("'", "''"))'
"@
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
    $pwshPath = (Get-Process -Id $PID).Path

    try {
        Write-Information "Starting an isolated Microsoft Graph authentication process for $($ParameterSets.Count) DLP alert lookup(s) to avoid Exchange/Graph identity-library conflicts." -InformationAction Continue
        # Out-Host keeps device-code prompts visible without letting child console text leak into this function's return value.
        & $pwshPath -NoLogo -NoProfile -EncodedCommand $encodedCommand | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "The isolated Microsoft Graph process exited with code $LASTEXITCODE. Action: Complete the displayed sign-in and verify SecurityAlert.Read.All consent and a Security Reader role."
        }
        if (-not (Test-Path -LiteralPath $temporaryResultPath)) {
            throw 'The isolated Microsoft Graph process returned no result file. Action: Retry and complete the displayed sign-in.'
        }

        @(Import-Clixml -LiteralPath $temporaryResultPath)
    }
    finally {
        Remove-Item -LiteralPath $temporaryResultPath -Force -ErrorAction SilentlyContinue
    }
}

