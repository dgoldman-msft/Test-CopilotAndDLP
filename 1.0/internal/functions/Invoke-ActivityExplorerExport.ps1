function Invoke-ActivityExplorerExport {
    <#
    .SYNOPSIS
    Thin wrapper around Export-ActivityExplorerData for testability.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [datetime] $StartTime,

        [Parameter(Mandatory)]
        [datetime] $EndTime,

        [string] $PageCookie,

        [ValidateRange(1, 5000)]
        [int] $PageSize = 5000
    )

    $parameters = @{
        StartTime    = $StartTime
        EndTime      = $EndTime
        OutputFormat = 'Json'
        PageSize     = $PageSize
        Filter1      = @('Workload', 'Copilot')
        Filter2      = @('Activity', 'CopilotInteraction', 'DLPRuleMatch', 'DLPRuleEnforce', 'DLPInfo')
    }
    if ($PageCookie) {
        $parameters.PageCookie = $PageCookie
    }

    Export-ActivityExplorerData @parameters
}
