#Requires -Version 7.2

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\1.0\Test-CopilotAndDLP.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-CopilotDlpSensitiveInfoType' {
    It 'returns all bundled sensitive information types by default' {
        $result = Get-CopilotDlpSensitiveInfoType

        $result.Count | Should -BeGreaterThan 300
        $result[0].PSTypeNames | Should -Contain 'CopilotDlp.SensitiveInfoType'
    }

    It 'includes the built-in Credit card number and Social Security Number types' {
        $result = Get-CopilotDlpSensitiveInfoType

        $result.Name | Should -Contain 'Credit card number'
        $result.Name | Should -Contain 'U.S. social security number (SSN)'
    }

    It 'filters by wildcard name' {
        $result = Get-CopilotDlpSensitiveInfoType -Name '*passport*'

        $result.Count | Should -BeGreaterThan 5
        $result.Name | ForEach-Object { $_ | Should -BeLike '*passport*' }
    }

    It 'returns a Microsoft Learn documentation link for each entry' {
        $result = Get-CopilotDlpSensitiveInfoType -Name 'Credit card number'

        $result.DocUrl | Should -Be 'https://learn.microsoft.com/en-us/purview/sit-defn-credit-card-number'
    }

    It 'returns nothing for a name that does not match the catalog' {
        $result = Get-CopilotDlpSensitiveInfoType -Name 'Does not exist as a SIT'

        $result | Should -BeNullOrEmpty
    }
}
