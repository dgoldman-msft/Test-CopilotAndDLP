#Requires -Version 7.2

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\1.0\Test-CopilotAndDLP.psd1'
    Import-Module $modulePath -Force
}

Describe 'Search-CopilotDlpAuditEvent' {
    BeforeEach {
        Mock -ModuleName Test-CopilotAndDLP Get-Module { [pscustomobject]@{ Name = 'ExchangeOnlineManagement' } }
        Mock -ModuleName Test-CopilotAndDLP Install-Module
        Mock -ModuleName Test-CopilotAndDLP Import-Module
        Mock -ModuleName Test-CopilotAndDLP Connect-ExchangeOnline
    }

    It 'searches CopilotInteraction records for the requested user and window' {
        Mock -ModuleName Test-CopilotAndDLP Invoke-UnifiedAuditLogSearch {
            @(
                [pscustomobject]@{
                    CreationDate = Get-Date '2026-09-02T12:00:00Z'
                    UserIds      = 'dlp-tester@contoso.example'
                    Operations   = 'CopilotInteraction'
                    RecordType   = 'CopilotInteraction'
                    AuditData    = '{"Workload":"Copilot","AppHost":"M365ChatCopilot"}'
                }
            )
        }

        $result = Search-CopilotDlpAuditEvent -UserPrincipalName 'dlp-tester@contoso.example' -StartDateUtc (Get-Date '2026-09-02T11:00:00Z')

        $result.PSTypeNames | Should -Contain 'CopilotDlp.AuditEvent'
        $result.UserId | Should -Be 'dlp-tester@contoso.example'
        $result.Workload | Should -Be 'Copilot'
        Should -Invoke Invoke-UnifiedAuditLogSearch -ModuleName Test-CopilotAndDLP -ParameterFilter {
            $RecordType -eq 'CopilotInteraction' -and $UserIds -eq 'dlp-tester@contoso.example'
        } -Times 1 -Exactly
    }

    It 'accepts a Test-CopilotAndDLP result object by pipeline' {
        Mock -ModuleName Test-CopilotAndDLP Invoke-UnifiedAuditLogSearch { @() }

        $validationResult = [pscustomobject]@{
            PSTypeName   = 'CopilotDlp.ValidationResult'
            TestUser     = 'dlp-tester@contoso.example'
            StartedAtUtc = (Get-Date).ToUniversalTime().AddMinutes(-10).ToString('o')
        }

        $null = $validationResult | Search-CopilotDlpAuditEvent

        Should -Invoke Invoke-UnifiedAuditLogSearch -ModuleName Test-CopilotAndDLP -ParameterFilter {
            $UserIds -eq 'dlp-tester@contoso.example'
        } -Times 1 -Exactly
    }

    It 'returns nothing when no matching audit records are found' {
        Mock -ModuleName Test-CopilotAndDLP Invoke-UnifiedAuditLogSearch { @() }

        $result = Search-CopilotDlpAuditEvent -UserPrincipalName 'dlp-tester@contoso.example' -StartDateUtc (Get-Date).ToUniversalTime().AddHours(-1)

        $result | Should -BeNullOrEmpty
    }
}
