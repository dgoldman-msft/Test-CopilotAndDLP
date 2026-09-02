function Install-RequiredGraphModule {
    <#
    .SYNOPSIS
    Ensures a required module is installed and imported, logging each step.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [ValidateNotNullOrEmpty()]
        [string] $RunId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $LogFile
    )

    $prefix = if ($RunId) { "[$RunId] " } else { '' }

    if (Get-Module -ListAvailable -Name $Name) {
        Write-ToLogFile -StringObject "$($prefix)Module '$Name' is already installed." -LogFile $LogFile
    }
    else {
        Write-ToLogFile -StringObject "$($prefix)Module '$Name' is not installed. Installing for the current user." -LogFile $LogFile
        if ($PSCmdlet.ShouldProcess($Name, 'Install module')) {
            Install-Module -Name $Name -Scope CurrentUser -Force -ErrorAction Stop
            Write-ToLogFile -StringObject "$($prefix)Module '$Name' installed." -LogFile $LogFile
        }
    }

    Write-ToLogFile -StringObject "$($prefix)Importing module '$Name'." -LogFile $LogFile
    Import-Module -Name $Name -ErrorAction Stop
    Write-ToLogFile -StringObject "$($prefix)Module '$Name' imported." -LogFile $LogFile
}
