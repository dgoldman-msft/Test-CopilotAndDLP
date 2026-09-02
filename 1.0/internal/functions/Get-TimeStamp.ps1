function Get-TimeStamp {
    <#
    .SYNOPSIS
    Returns a bracketed log timestamp, modeled after Start-PurviewOrphanedLabelRemediation.
    #>
    [CmdletBinding()]
    param()

    return '[{0:MM/dd/yy} {0:HH:mm:ss}] -' -f (Get-Date)
}
