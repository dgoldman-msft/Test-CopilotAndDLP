@{
    RootModule        = 'Test-CopilotAndDLP.psm1'
    ModuleVersion     = '1.0'
    GUID              = 'd6c38774-a617-4b45-a802-d3886db53f6b'
    Author            = 'Dave Goldman'
    CompanyName       = ' '
    Copyright         = '(c) Dave Goldman. All rights reserved.'
    Description       = 'Submits approved synthetic sensitive-data prompts to Microsoft 365 Copilot Chat for Microsoft Purview DLP validation.'
    PowerShellVersion = '7.2'
    FunctionsToExport = @('Test-CopilotAndDLP', 'Search-CopilotDlpAuditEvent', 'Get-CopilotDlpSensitiveInfoType')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('M365', 'Copilot', 'Purview', 'DLP', 'MicrosoftGraph')
            ProjectUri = 'https://github.com/dgoldman-msft/Test-CopilotAndDLP'
            LicenseUri = 'https://github.com/dgoldman-msft/Test-CopilotAndDLP/blob/main/LICENSE'
        }
    }
}
