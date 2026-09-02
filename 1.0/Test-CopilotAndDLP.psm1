Set-StrictMode -Version Latest

$script:CopilotDlpModuleRoot = $PSScriptRoot

# Internal helper functions
. (Join-Path $PSScriptRoot 'internal\functions\Get-CopilotResponseText.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Get-SensitiveInfoTypeCatalog.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Get-SensitiveTextHash.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Get-TimeStamp.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Install-RequiredGraphModule.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Invoke-UnifiedAuditLogSearch.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Write-CopilotDlpCorrelationRecord.ps1')
. (Join-Path $PSScriptRoot 'internal\functions\Write-ToLogFile.ps1')

# Public functions
. (Join-Path $PSScriptRoot 'functions\Test-CopilotAndDLP.ps1')
. (Join-Path $PSScriptRoot 'functions\Search-CopilotDlpAuditEvent.ps1')
. (Join-Path $PSScriptRoot 'functions\Get-CopilotDlpSensitiveInfoType.ps1')

Export-ModuleMember -Function 'Test-CopilotAndDLP', 'Search-CopilotDlpAuditEvent', 'Get-CopilotDlpSensitiveInfoType'
