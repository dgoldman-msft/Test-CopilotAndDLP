#Requires -Version 7.2

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\1.0\Test-CopilotAndDLP.psd1'
    Import-Module $modulePath -Force
}

Describe 'Test-CopilotAndDLP' {
    It 'exports only the public commands' {
        $commands = Get-Command -Module Test-CopilotAndDLP
        $commands.Name | Sort-Object | Should -Be @('Get-CopilotDlpSensitiveInfoType', 'Search-CopilotDlpAuditEvent', 'Test-CopilotAndDLP')
    }

    It 'previews safely without authenticating' {
        InModuleScope Test-CopilotAndDLP {
            Mock Import-Module
            $result = Test-CopilotAndDLP -TestSensitiveText 'SYNTHETIC-123' -LogPath (Join-Path $TestDrive 'preview.log') -WhatIf

            $result.PSTypeNames | Should -Contain 'CopilotDlp.ValidationPreview'
            $result.Action | Should -BeLike 'Would submit*'
            $result.PSObject.Properties.Value -join ' ' | Should -Not -Match 'SYNTHETIC-123'
            Should -Invoke Import-Module -Times 0
        }
    }

    It 'rejects whitespace-only sensitive text' {
        { Test-CopilotAndDLP -TestSensitiveText '   ' -WhatIf } | Should -Throw
    }

    It 'rejects a -SensitiveInfoTypeLabel that is not in the bundled catalog' {
        { Test-CopilotAndDLP -TestSensitiveText 'x' -SensitiveInfoTypeLabel 'Not A Real SIT' -WhatIf } | Should -Throw
    }

    Context 'with mocked Microsoft Graph' {
        BeforeEach {
            Mock -ModuleName Test-CopilotAndDLP Get-Module { [pscustomobject]@{ Name = 'Microsoft.Graph.Authentication' } }
            Mock -ModuleName Test-CopilotAndDLP Install-Module
            Mock -ModuleName Test-CopilotAndDLP Import-Module
            Mock -ModuleName Test-CopilotAndDLP Connect-MgGraph
            Mock -ModuleName Test-CopilotAndDLP Get-MgContext {
                [pscustomobject]@{
                    Account  = 'dlp-tester@contoso.example'
                    TenantId = 'tenant-id'
                }
            }
        }

        It 'creates a conversation, submits the prompt, and returns a result' {
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                if ($Uri -like '*/chat') {
                    return @{ messages = @(@{ text = 'Prompt processing was blocked.' }) }
                }
                return @{ id = 'conversation-id' }
            }

            $logPath = Join-Path $TestDrive 'success.jsonl'
            $result = Test-CopilotAndDLP `
                -TestSensitiveText 'SYNTHETIC-456' `
                -ResultPath $logPath `
                -LogPath (Join-Path $TestDrive 'success.log') `
                -Confirm:$false

            $result.SubmissionStatus | Should -Be 'Submitted'
            $result.ConversationId | Should -Be 'conversation-id'
            $result.CopilotResponse | Should -Be 'Prompt processing was blocked.'
            Should -Invoke Invoke-MgGraphRequest -ModuleName Test-CopilotAndDLP -Times 2 -Exactly
            Test-Path -LiteralPath $logPath | Should -BeTrue
        }

        It 'embeds the default U.S. social security number (SSN) label when -SensitiveInfoTypeLabel is not specified' {
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                if ($Uri -like '*/chat') {
                    return @{ messages = @(@{ text = 'ok' }) }
                }
                return @{ id = 'conversation-id' }
            }

            $null = Test-CopilotAndDLP `
                -TestSensitiveText 'SYNTHETIC-SSN' `
                -ResultPath (Join-Path $TestDrive 'default-label.jsonl') `
                -LogPath (Join-Path $TestDrive 'default-label.log') `
                -Confirm:$false

            Should -Invoke Invoke-MgGraphRequest -ModuleName Test-CopilotAndDLP -ParameterFilter {
                $Uri -like '*/chat' -and $Body -like '*U.S. social security number (SSN): SYNTHETIC-SSN*'
            } -Times 1 -Exactly
        }

        It 'embeds a custom -SensitiveInfoTypeLabel in the prompt instead of the default' {
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                if ($Uri -like '*/chat') {
                    return @{ messages = @(@{ text = 'ok' }) }
                }
                return @{ id = 'conversation-id' }
            }

            $null = Test-CopilotAndDLP `
                -TestSensitiveText '4111111111111111' `
                -SensitiveInfoTypeLabel 'Credit Card Number' `
                -ResultPath (Join-Path $TestDrive 'cc.jsonl') `
                -LogPath (Join-Path $TestDrive 'cc.log') `
                -Confirm:$false

            Should -Invoke Invoke-MgGraphRequest -ModuleName Test-CopilotAndDLP -ParameterFilter {
                $Uri -like '*/chat' -and $Body -like '*Credit Card Number: 4111111111111111*'
            } -Times 1 -Exactly
        }

        It 'returns ApiRejected and records safe correlation data when Graph rejects the request' {
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                throw 'Synthetic API rejection included SYNTHETIC-789'
            }

            $logPath = Join-Path $TestDrive 'rejected.jsonl'
            $result = Test-CopilotAndDLP `
                -TestSensitiveText 'SYNTHETIC-789' `
                -ResultPath $logPath `
                -LogPath (Join-Path $TestDrive 'rejected.log') `
                -Confirm:$false `
                -ErrorAction SilentlyContinue

            $result.SubmissionStatus | Should -Be 'ApiRejected'
            $result.Error | Should -Match 'Synthetic API rejection'
            $result.Error | Should -Match '\[REDACTED\]'
            (Get-Content -LiteralPath $logPath -Raw) | Should -Not -Match 'SYNTHETIC-789'
        }

        It 'does not disclose sensitive or response text in the JSONL log' {
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                if ($Uri -like '*/chat') {
                    return @{ messages = @(@{ text = 'RESPONSE-MUST-NOT-BE-LOGGED' }) }
                }
                return @{ id = 'conversation-id' }
            }

            $logPath = Join-Path $TestDrive 'safe.jsonl'
            $textLogPath = Join-Path $TestDrive 'safe.log'
            $null = Test-CopilotAndDLP `
                -TestSensitiveText 'VALUE-MUST-NOT-BE-LOGGED' `
                -ResultPath $logPath `
                -LogPath $textLogPath `
                -Confirm:$false

            $log = Get-Content -LiteralPath $logPath -Raw
            $log | Should -Not -Match 'VALUE-MUST-NOT-BE-LOGGED'
            $log | Should -Not -Match 'RESPONSE-MUST-NOT-BE-LOGGED'
            ($log | ConvertFrom-Json).SensitiveTextSha256 | Should -Match '^[a-f0-9]{64}$'

            $textLog = Get-Content -LiteralPath $textLogPath -Raw
            $textLog | Should -Not -Match 'VALUE-MUST-NOT-BE-LOGGED'
            $textLog | Should -Not -Match 'RESPONSE-MUST-NOT-BE-LOGGED'
        }

        It 'does not reinstall Microsoft.Graph.Authentication when it is already installed' {
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                if ($Uri -like '*/chat') {
                    return @{ messages = @(@{ text = 'ok' }) }
                }
                return @{ id = 'conversation-id' }
            }

            $null = Test-CopilotAndDLP `
                -TestSensitiveText 'SYNTHETIC-999' `
                -ResultPath (Join-Path $TestDrive 'installed.jsonl') `
                -LogPath (Join-Path $TestDrive 'installed.log') `
                -Confirm:$false

            Should -Invoke Install-Module -ModuleName Test-CopilotAndDLP -Times 0
            Should -Invoke Import-Module -ModuleName Test-CopilotAndDLP -ParameterFilter { $Name -eq 'Microsoft.Graph.Authentication' } -Times 1 -Exactly
        }

        It 'installs Microsoft.Graph.Authentication for the current user when it is missing' {
            Mock -ModuleName Test-CopilotAndDLP Get-Module { $null }
            Mock -ModuleName Test-CopilotAndDLP Invoke-MgGraphRequest {
                if ($Uri -like '*/chat') {
                    return @{ messages = @(@{ text = 'ok' }) }
                }
                return @{ id = 'conversation-id' }
            }

            $null = Test-CopilotAndDLP `
                -TestSensitiveText 'SYNTHETIC-000' `
                -ResultPath (Join-Path $TestDrive 'missing.jsonl') `
                -LogPath (Join-Path $TestDrive 'missing.log') `
                -Confirm:$false

            Should -Invoke Install-Module -ModuleName Test-CopilotAndDLP -ParameterFilter {
                $Name -eq 'Microsoft.Graph.Authentication' -and $Scope -eq 'CurrentUser'
            } -Times 1 -Exactly
        }
    }
}
