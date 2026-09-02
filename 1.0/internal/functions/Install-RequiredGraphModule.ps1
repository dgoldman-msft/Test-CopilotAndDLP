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
        [string] $LogFile,

        [version] $MinimumVersion
    )

    $prefix = if ($RunId) { "[$RunId] " } else { '' }

    $loadedModule = Get-Module -Name $Name |
        Where-Object { $_ -is [Management.Automation.PSModuleInfo] } |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($loadedModule) {
        if (-not $MinimumVersion -or $loadedModule.Version -ge $MinimumVersion) {
            Write-ToLogFile -StringObject "$($prefix)Reusing loaded module '$Name' version $($loadedModule.Version)." -LogFile $LogFile
            return
        }

        $exception = [InvalidOperationException]::new(
            "Module '$Name' version $($loadedModule.Version) is already loaded, but version $MinimumVersion or later is required. PowerShell can't replace its loaded .NET assemblies safely. Action: Close this terminal, open a new PowerShell 7 terminal, import Test-CopilotAndDLP again, and rerun the command."
        )
        $errorRecord = [Management.Automation.ErrorRecord]::new(
            $exception,
            'CopilotDlpModuleRestartRequired',
            [Management.Automation.ErrorCategory]::ResourceBusy,
            $loadedModule
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    $installedModule = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    $installedVersion = if ($installedModule -and $installedModule.PSObject.Properties.Name -contains 'Version') {
        [version] $installedModule.Version
    }
    else {
        $null
    }
    $requiresInstall = -not $installedModule -or ($MinimumVersion -and (-not $installedVersion -or $installedVersion -lt $MinimumVersion))

    if (-not $requiresInstall) {
        $versionText = if ($installedVersion) { " version $installedVersion" } else { '' }
        Write-ToLogFile -StringObject "$($prefix)Module '$Name'$versionText is already installed." -LogFile $LogFile
    }
    else {
        $reason = if ($installedModule) {
            "Installed version $installedVersion is below required version $MinimumVersion"
        }
        else {
            'Module is not installed'
        }
        Write-ToLogFile -StringObject "$($prefix)$reason. Installing '$Name' for the current user." -LogFile $LogFile
        if ($PSCmdlet.ShouldProcess($Name, 'Install module')) {
            $installParameters = @{
                Name        = $Name
                Scope       = 'CurrentUser'
                Force       = $true
                ErrorAction = 'Stop'
            }
            if ($MinimumVersion) {
                $installParameters.MinimumVersion = $MinimumVersion
            }
            Install-Module @installParameters
            Write-ToLogFile -StringObject "$($prefix)Module '$Name' installed." -LogFile $LogFile
        }
    }

    Write-ToLogFile -StringObject "$($prefix)Importing module '$Name'." -LogFile $LogFile
    $importParameters = @{ Name = $Name; ErrorAction = 'Stop' }
    if ($MinimumVersion) {
        $importParameters.MinimumVersion = $MinimumVersion
    }
    Import-Module @importParameters
    Write-ToLogFile -StringObject "$($prefix)Module '$Name' imported." -LogFile $LogFile
}
