function Write-ToLogFile {
    <#
    .SYNOPSIS
    Writes a timestamped line to a log file, modeled after Start-PurviewOrphanedLabelRemediation.

    .DESCRIPTION
    Adapted to emit console output via Write-Information instead of Write-Host so
    the message is visible without relying on the host UI, and to satisfy the
    PSAvoidUsingWriteHost analyzer rule.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string] $StringObject,

        [Parameter(Mandatory)]
        [string] $LogFile,

        [switch] $LogOnly
    )

    $targetDirectory = Split-Path -Path $LogFile -Parent
    if ($targetDirectory -and -not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -Path $targetDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    if (-not $LogOnly -and $StringObject -ne '') {
        Write-Information $StringObject -InformationAction Continue
    }

    if ($StringObject -eq '') {
        Add-Content -LiteralPath $LogFile -Value '' -Encoding utf8
        return
    }

    $content = $StringObject
    while ($content.StartsWith("`n")) {
        Add-Content -LiteralPath $LogFile -Value '' -Encoding utf8
        $content = $content.Substring(1)
    }

    if ($content) {
        Add-Content -LiteralPath $LogFile -Value "$(Get-TimeStamp) $content" -Encoding utf8
    }
}
