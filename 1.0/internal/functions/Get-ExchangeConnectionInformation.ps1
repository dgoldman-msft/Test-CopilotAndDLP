function Get-ExchangeConnectionInformation {
    <#
    .SYNOPSIS
    Returns Exchange Online connection metadata when the command is available.
    #>
    [CmdletBinding()]
    param()

    $command = Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue
    if ($command) {
        & $command -ErrorAction SilentlyContinue
    }
}
