function Test-CopilotAndDLP {
    <#
    .SYNOPSIS
    Submits a synthetic sensitive-data prompt to Microsoft 365 Copilot Chat.

    .DESCRIPTION
    Creates a Microsoft 365 Copilot conversation and sends a prompt through the
    preview Microsoft Graph Copilot Chat API. Correlate the returned run metadata
    with the expected Microsoft Purview DLP alert or audit event. A successful API
    response proves prompt submission only; it does not prove that a DLP rule matched.

    This API requires delegated authentication, a Microsoft 365 Copilot add-on
    license, and all requested delegated scopes. Use only synthetic test data
    approved by your organization.

    .PARAMETER TestSensitiveText
    One or more synthetic text values expected to match the sensitive information
    type under test. The command adds the corroborative phrase from
    -SensitiveInfoTypeLabel next to each value. Accepts an array, a comma-separated
    list, or pipeline input; the command submits one Copilot conversation per value
    and returns one result object per value, reusing a single Microsoft Graph
    sign-in across the batch.

    .PARAMETER SensitiveInfoTypeLabel
    Corroborative keyword phrase paired with -TestSensitiveText in the prompt, to
    raise match confidence for the targeted sensitive information type. Must be
    an exact name from the bundled Microsoft Purview sensitive information type
    catalog (tab-completable); use Get-CopilotDlpSensitiveInfoType to browse all
    supported names and their Microsoft Learn documentation links. Defaults to
    'U.S. social security number (SSN)'.

    .PARAMETER TenantId
    Microsoft Entra tenant ID or verified tenant domain. When omitted, interactive
    sign-in determines the tenant.

    .PARAMETER TimeZone
    IANA time-zone name sent as the Copilot location hint.

    .PARAMETER EnableWebSearch
    Enables web-search grounding. It is disabled by default to isolate prompt DLP.

    .PARAMETER UseDeviceCode
    Uses device-code authentication instead of Windows Web Account Manager.

    .PARAMETER ResultPath
    JSON Lines correlation log. Sensitive text and Copilot response text are never
    written to this file.

    .PARAMETER LogPath
    Timestamped text log recording progress for this run. Sensitive text and
    Copilot response text are never written to this file.

    .EXAMPLE
    Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -WhatIf

    Previews the test without authentication or network calls.

    .EXAMPLE
    Test-CopilotAndDLP -TenantId 'contoso.onmicrosoft.com' `
        -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false -Verbose

    Authenticates, submits the prompt, and records non-sensitive correlation data.

    .EXAMPLE
    Test-CopilotAndDLP -TestSensitiveText '4111111111111111' `
        -SensitiveInfoTypeLabel 'Credit card number' -Confirm:$false

    Tests the Credit card number sensitive information type using a
    well-known, publicly documented test card number instead of an SSN.

    .EXAMPLE
    'REPLACE-WITH-APPROVED-VALUE-1', 'REPLACE-WITH-APPROVED-VALUE-2' |
        Test-CopilotAndDLP -Confirm:$false

    Runs a two-scenario regression batch, signing in to Microsoft Graph once and
    submitting one prompt per piped value.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({
            foreach ($value in $_) {
                if ([string]::IsNullOrWhiteSpace($value)) {
                    throw 'TestSensitiveText values must not be null or whitespace.'
                }
            }
            $true
        })]
        [string[]]
        $TestSensitiveText,

        # Kept in sync with 1.0/data/SensitiveInfoTypes.psd1 (Microsoft Learn SIT catalog).
        [ValidateSet(
            'ABA Routing Number',
            'All Credential Types',
            'All full names',
            'All medical terms and conditions',
            'All Physical Addresses',
            'Amazon S3 Client Secret Access Key',
            'Argentina national identity (DNI) number',
            'Argentina Unique Tax Identification Key (CUIT/CUIL)',
            'ASP.NET machine Key',
            'Australia bank account number',
            "Australia Driver's License Number",
            'Australia medical account number',
            'Australia passport number',
            'Australia physical addresses',
            'Australia tax file number',
            'Australian Business Number',
            'Australian Company Number',
            "Austria Driver's License Number",
            'Austria identity card',
            'Austria passport number',
            'Austria physical addresses',
            'Austria social security number',
            'Austria tax identification number',
            'Austria Value Added Tax (VAT) Number',
            'Azure App Service deployment password',
            'Azure Batch shared access key',
            'Azure Bot Framework secret key',
            'Azure Bot service app secret',
            'Azure Cognitive Search API key',
            'Azure Cognitive Service key',
            'Azure Container Registry access key',
            'Azure Cosmos DB account access key',
            'Azure Databricks personal access token',
            'Azure DevOps app secret',
            'Azure DevOps personal access token',
            'Azure DocumentDB auth key',
            'Azure EventGrid access key',
            'Azure Function Master / API key',
            'Azure IAAS database connection string and Azure SQL connection string',
            'Azure IoT connection string',
            'Azure IoT shared access key',
            'Azure Logic app shared access signature',
            'Azure Machine Learning web service API key',
            'Azure Maps subscription key',
            'Azure publish setting password',
            'Azure Redis cache connection string',
            'Azure Redis cache connection string password',
            'Azure SAS',
            'Azure service bus connection string',
            'Azure service bus shared access signature',
            'Azure Shared Access key / Web Hook token',
            'Azure SignalR access key',
            'Azure SQL connection string',
            'Azure storage account access key',
            'Azure storage account key',
            'Azure Storage account key (generic)',
            'Azure Storage account shared access signature',
            'Azure Storage account shared access signature for high risk resources',
            'Azure subscription management certificate',
            "Belgium driver's license number",
            'Belgium national number',
            'Belgium passport number',
            'Belgium physical addresses',
            'Belgium value added tax number',
            'Blood test terms',
            'Brand medication names',
            'Brazil CPF number',
            'Brazil legal entity number (CNPJ)',
            'Brazil National ID Card (RG)',
            'Brazil physical addresses',
            "Bulgaria driver's license number",
            'Bulgaria passport number',
            'Bulgaria physical addresses',
            'Bulgaria uniform civil number',
            'Canada bank account number',
            "Canada driver's license number",
            'Canada health service number',
            'Canada passport number',
            'Canada personal health identification number (PHIN)',
            'Canada physical addresses',
            'Canada social insurance number',
            'Chile identity card number',
            'China physical addresses',
            'China resident identity card (PRC) number',
            'Client secret / API key',
            'Colombia national ID',
            'Colombia tax identification number',
            'Credit card number',
            "Croatia driver's license number",
            'Croatia identity card number',
            'Croatia passport number',
            'Croatia personal identification (OIB) number',
            'Croatia physical addresses',
            "Cyprus Driver's License Number",
            'Cyprus identity card',
            'Cyprus passport number',
            'Cyprus physical addresses',
            'Cyprus tax identification number',
            "Czech driver's license number",
            'Czech passport number',
            'Czech personal identity number',
            'Czech Republic physical addresses',
            "Denmark driver's license number",
            'Denmark passport number',
            'Denmark personal identification number',
            'Denmark physical addresses',
            'Diseases',
            'Drug Enforcement Agency (DEA) number',
            'Ecuador Unique Identification Number',
            "Estonia driver's license number",
            'Estonia passport number',
            'Estonia Personal Identification Code',
            'Estonia physical addresses',
            'EU debit card number',
            "EU driver's license number",
            'EU national identification number',
            'EU passport number',
            'EU Social Security Number (SSN) or Equivalent ID',
            'EU Tax Identification Number (TIN)',
            "Finland driver's license number",
            'Finland European health insurance number',
            'Finland national ID',
            'Finland passport number',
            'Finland physical addresses',
            "France driver's license number",
            'France health insurance number',
            'France national id card (CNI)',
            'France passport number',
            'France physical addresses',
            'France social security number (INSEE)',
            'France Tax Identification Number (numero SPI.)',
            'France value added tax number',
            'General password',
            'General Symmetric key',
            'Generic medication names',
            "German Driver's License Number",
            'German Passport Number',
            'Germany identity card number',
            'Germany physical addresses',
            'Germany tax identification number',
            'Germany value added tax number',
            'GitHub Personal Access Token',
            'Google API key',
            "Greece driver's license number",
            'Greece national ID card',
            'Greece passport number',
            'Greece physical addresses',
            'Greece Social Security Number (AMKA)',
            'Greek Tax Identification Number',
            'Greenland physical addresses',
            'Hong Kong identity card (HKID) number',
            'Http authorization header',
            'Hungarian Social Security Number (TAJ)',
            'Hungarian Value Added Tax Number',
            "Hungary driver's license number",
            'Hungary passport number',
            'Hungary personal identification number',
            'Hungary physical addresses',
            'Hungary tax identification number',
            'Iceland physical addresses',
            'Impairments Listed In The U.S. Disability Evaluation Under Social Security',
            "India driver's License Number",
            'India GST Number',
            'India permanent account number (PAN)',
            'India unique identification (Aadhaar) number',
            'India Voter Id Card',
            'Indonesia Drivers License Number',
            'Indonesia identity card (KTP) number',
            'Indonesia passport number',
            'International banking account number (IBAN)',
            'International classification of diseases (ICD-10-CM)',
            'International classification of diseases (ICD-9-CM)',
            'IP address',
            'IP Address v4',
            'IP Address v6',
            "Ireland driver's license number",
            'Ireland passport number',
            'Ireland personal public service (PPS) number',
            'Ireland physical addresses',
            'Israel bank account number',
            'Israel National ID',
            "Italy driver's license number",
            'Italy fiscal code',
            'Italy passport number',
            'Italy physical addresses',
            'Italy value added tax number',
            'Japan bank account number',
            "Japan driver's license number",
            'Japan passport number',
            'Japan physical addresses',
            'Japan resident registration number',
            'Japan social insurance number (SIN)',
            'Japanese My Number Corporate',
            'Japanese My Number Personal',
            'Japanese Residence Card Number',
            'Lab test terms',
            "Latvia driver's license number",
            'Latvia passport number',
            'Latvia personal code',
            'Latvia physical addresses',
            'Liechtenstein physical addresses',
            'Lifestyles that relate to medical conditions',
            "Lithuania driver's license number",
            'Lithuania passport number',
            'Lithuania personal code',
            'Lithuania physical addresses',
            "Luxembourg Driver's License Number",
            'Luxembourg National Identification Number (Natural persons)',
            'Luxembourg National Identification Number (Non-natural persons)',
            'Luxembourg Passport Number',
            'Luxembourg Physical Addresses',
            'Malaysia Identity Card Number',
            'Malaysia passport number',
            "Malta driver's license number",
            'Malta identity card number',
            'Malta passport number',
            'Malta physical addresses',
            'Malta Tax ID Number',
            'Medical Specialities',
            'Medicare Beneficiary Identifier (MBI) card',
            'Mexico Unique Population Registry Code (CURP)',
            'Microsoft Bing maps key',
            'Microsoft Entra client access token',
            'Microsoft Entra client secret',
            'Microsoft Entra user Credentials',
            "Netherlands citizen's service (BSN) number",
            "Netherlands driver's license number",
            'Netherlands passport number',
            'Netherlands physical addresses',
            'Netherlands tax identification number',
            'Netherlands value added tax number',
            'New Zealand bank account number',
            'New Zealand Driver License Number',
            'New Zealand inland revenue number',
            'New Zealand ministry of health number',
            'New Zealand physical addresses',
            'New Zealand social welfare number',
            'Norway Identity Number',
            'Norway physical addresses',
            'Philippines National ID',
            'Philippines passport number',
            'Philippines Unified Multi-Purpose ID Number',
            "Poland driver's license number",
            'Poland identity card',
            'Poland national ID (PESEL)',
            'Poland Passport Number',
            'Poland physical addresses',
            'Poland REGON number',
            'Poland tax identification number',
            'Portugal citizen card number',
            "Portugal driver's license number",
            'Portugal passport number',
            'Portugal physical addresses',
            'Portugal tax identification number',
            'Qatari ID Card Number',
            "Romania driver's license number",
            'Romania passport number',
            'Romania personal numeric code (CNP)',
            'Romania physical addresses',
            'Russia physical addresses',
            'Russia taxpayer identification number',
            'Russian Passport Number (Domestic)',
            'Russian Passport Number (International)',
            'Saudi Arabia National ID',
            "Singapore driver's license number",
            'Singapore national registration identity card (NRIC) number',
            'Singapore passport number',
            'Singapore physical addresses',
            'Slack access token',
            "Slovakia driver's license number",
            'Slovakia passport number',
            'Slovakia personal number',
            'Slovakia physical addresses',
            "Slovenia driver's license number",
            'Slovenia passport number',
            'Slovenia physical addresses',
            'Slovenia tax identification number',
            'Slovenia Unique Master Citizen Number',
            'South Africa identification number',
            'South Africa physical addresses',
            "South Korea driver's license number",
            'South Korea passport number',
            'South Korea resident registration number',
            'Spain DNI',
            "Spain driver's license number",
            'Spain passport number',
            'Spain physical addresses',
            'Spain social security number (SSN)',
            'Spain tax identification number',
            'SQL Server connection string',
            'Surgical procedures',
            "Sweden driver's license number",
            'Sweden national ID',
            'Sweden passport number',
            'Sweden physical addresses',
            'Sweden tax identification number',
            'SWIFT code',
            'Swiss Social Security Number AHV',
            'Switzerland physical addresses',
            'Taiwan National ID',
            'Taiwan passport number',
            'Taiwan Resident Certificate (ARC/TARC)',
            'Thai population identification code',
            'Turkey national identification number',
            'Turkey physical addresses',
            'Types of medication',
            'U.A.E. identity card number',
            'U.A.E. passport number',
            "U.K. driver's license number",
            'U.K. electoral roll number',
            'U.K. national health service number',
            'U.K. national insurance number (NINO)',
            'U.K. physical addresses',
            'U.K. Unique Taxpayer Reference Number',
            'U.S. bank account number',
            "U.S. driver's license number",
            'U.S. individual taxpayer identification number (ITIN)',
            'U.S. physical addresses',
            'U.S. social security number (SSN)',
            'U.S./U.K. passport number',
            'Ukraine Passport Number (Domestic)',
            'Ukraine Passport Number (International)',
            'Ukraine physical addresses',
            'User login credentials',
            'X.509 certificate private key'
        )]
        [string]
        $SensitiveInfoTypeLabel = 'U.S. social security number (SSN)',

        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string]
        $TenantId,

        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string]
        $TimeZone = 'America/New_York',

        [switch]
        $EnableWebSearch,

        [switch]
        $UseDeviceCode,

        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string]
        $ResultPath = (Join-Path (Get-Location).Path 'copilot-dlp-results.jsonl'),

        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string]
        $LogPath = (Join-Path (Get-Location).Path 'copilot-dlp.log')
    )

    begin {
        $requiredScopes = @(
            'Sites.Read.All'
            'Mail.Read'
            'People.Read.All'
            'OnlineMeetingTranscript.Read.All'
            'Chat.Read'
            'ChannelMessage.Read.All'
            'ExternalItem.Read.All'
        )
        $graphConnected = $false
        $graphContext = $null
    }

    process {
        foreach ($testValue in $TestSensitiveText) {
            $runId = [guid]::NewGuid().ToString()
            $startedAt = [DateTimeOffset]::UtcNow

            Write-ToLogFile -StringObject "[$runId] Starting Copilot DLP validation run." -LogFile $LogPath

            if ($WhatIfPreference) {
                Write-ToLogFile -StringObject "[$runId] Preview mode (-WhatIf): no authentication or network calls will be made." -LogFile $LogPath
                [pscustomobject] @{
                    PSTypeName       = 'CopilotDlp.ValidationPreview'
                    RunId            = $runId
                    Action           = 'Would submit an approved synthetic prompt to Microsoft 365 Copilot'
                    TenantId         = $TenantId
                    TimeZone         = $TimeZone
                    WebSearchEnabled = [bool] $EnableWebSearch
                    Authentication   = if ($UseDeviceCode) { 'DeviceCode' } else { 'WAM' }
                    RequiredScopes   = $requiredScopes
                    ResultPath       = $ResultPath
                    LogPath          = $LogPath
                }
                continue
            }

            if (-not $graphConnected) {
                Install-RequiredGraphModule -Name 'Microsoft.Graph.Authentication' -RunId $runId -LogFile $LogPath

                $connectParameters = @{
                    Scopes    = $requiredScopes
                    NoWelcome = $true
                }
                if ($TenantId) {
                    $connectParameters.TenantId = $TenantId
                }
                if ($UseDeviceCode) {
                    $connectParameters.UseDeviceCode = $true
                }

                Write-ToLogFile -StringObject "[$runId] Connecting to Microsoft Graph with delegated permissions." -LogFile $LogPath
                Connect-MgGraph @connectParameters

                $graphContext = Get-MgContext
                if (-not $graphContext -or [string]::IsNullOrWhiteSpace([string] $graphContext.Account)) {
                    throw 'Microsoft Graph authentication did not return a signed-in account.'
                }

                Write-ToLogFile -StringObject "[$runId] Signed in as $($graphContext.Account) (tenant $($graphContext.TenantId))." -LogFile $LogPath
                $graphConnected = $true
            }
            else {
                Write-ToLogFile -StringObject "[$runId] Reusing the active Microsoft Graph sign-in for $($graphContext.Account)." -LogFile $LogPath
            }

            $target = "Microsoft 365 Copilot as $($graphContext.Account)"
            if (-not $PSCmdlet.ShouldProcess($target, 'Submit synthetic DLP validation prompt')) {
                Write-ToLogFile -StringObject "[$runId] Submission skipped (ShouldProcess declined)." -LogFile $LogPath
                continue
            }

            $prompt = @"
DLP automated validation test.
Test ID: $runId
$($SensitiveInfoTypeLabel): $testValue
This is synthetic test data. Do not retain or repeat it.
"@

            $requestBody = @{
                message = @{
                    text = $prompt
                }
                locationHint = @{
                    timeZone = $TimeZone
                }
                contextualResources = @{
                    webContext = @{
                        isWebEnabled = [bool] $EnableWebSearch
                    }
                }
            } | ConvertTo-Json -Depth 8

            $conversationId = $null
            $response = $null
            $submissionStatus = 'NotSubmitted'
            $errorMessage = $null

            try {
                Write-ToLogFile -StringObject "[$runId] Creating a Microsoft 365 Copilot conversation." -LogFile $LogPath
                $conversation = Invoke-CopilotGraphRequestWithRetry `
                    -Method POST `
                    -Uri 'https://graph.microsoft.com/beta/copilot/conversations' `
                    -ContentType 'application/json' `
                    -Body '{}'

                $conversationId = if ($conversation -is [Collections.IDictionary]) {
                    $conversation['id']
                }
                elseif ($null -ne $conversation -and $conversation.PSObject.Properties.Name -contains 'id') {
                    $conversation.id
                }

                if ([string]::IsNullOrWhiteSpace([string] $conversationId)) {
                    throw 'Copilot conversation creation returned no id.'
                }

                Write-ToLogFile -StringObject "[$runId] Conversation created: $conversationId. Submitting synthetic prompt." -LogFile $LogPath
                $response = Invoke-CopilotGraphRequestWithRetry `
                    -Method POST `
                    -Uri "https://graph.microsoft.com/beta/copilot/conversations/$conversationId/chat" `
                    -ContentType 'application/json' `
                    -Body $requestBody

                $submissionStatus = 'Submitted'
                Write-ToLogFile -StringObject "[$runId] Prompt submitted successfully." -LogFile $LogPath
            }
            catch {
                $submissionStatus = 'ApiRejected'
                $errorMessage = [regex]::Replace(
                    $_.Exception.Message,
                    [regex]::Escape($testValue),
                    '[REDACTED]',
                    [Text.RegularExpressions.RegexOptions]::IgnoreCase
                )
                Write-ToLogFile -StringObject "[$runId] Prompt submission was rejected: $errorMessage" -LogFile $LogPath
            }

            $record = [ordered] @{
                RunId               = $runId
                StartedAtUtc        = $startedAt.ToString('o')
                CompletedAtUtc      = [DateTimeOffset]::UtcNow.ToString('o')
                TestUser            = $graphContext.Account
                TenantId            = $graphContext.TenantId
                ConversationId      = $conversationId
                SubmissionStatus    = $submissionStatus
                ExpectedDlpOutcome  = 'PromptProcessingBlocked'
                SensitiveTextSha256 = Get-SensitiveTextHash -Text $testValue
                WebSearchEnabled    = [bool] $EnableWebSearch
                Error               = $errorMessage
            }

            Write-ToLogFile -StringObject "[$runId] Writing correlation record to $ResultPath." -LogFile $LogPath
            Write-CopilotDlpCorrelationRecord -Record $record -Path $ResultPath
            Write-ToLogFile -StringObject "[$runId] Run complete. SubmissionStatus: $submissionStatus." -LogFile $LogPath

            [pscustomobject] @{
                PSTypeName         = 'CopilotDlp.ValidationResult'
                RunId              = $record.RunId
                StartedAtUtc       = $record.StartedAtUtc
                TestUser           = $record.TestUser
                TenantId           = $record.TenantId
                ConversationId     = $record.ConversationId
                SubmissionStatus   = $record.SubmissionStatus
                ExpectedDlpOutcome = $record.ExpectedDlpOutcome
                CopilotResponse    = Get-CopilotResponseText -Response $response
                Error              = $record.Error
                ResultPath         = $ResultPath
                LogPath            = $LogPath
            }
        }
    }
}
