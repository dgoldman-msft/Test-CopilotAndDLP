@{
    # Sourced from the Microsoft Learn "Sensitive information type entity
    # definitions" index: https://learn.microsoft.com/purview/sit-sensitive-information-type-entity-definitions
    # Each DocSlug resolves to https://learn.microsoft.com/en-us/purview/<DocSlug>
    Entries = @(
        @{ Name = 'ABA Routing Number'; DocSlug = 'sit-defn-aba-routing' }
        @{ Name = 'All Credential Types'; DocSlug = 'sit-defn-all-creds' }
        @{ Name = 'All full names'; DocSlug = 'sit-defn-all-full-names' }
        @{ Name = 'All medical terms and conditions'; DocSlug = 'sit-defn-all-medical-terms-conditions' }
        @{ Name = 'All Physical Addresses'; DocSlug = 'sit-defn-all-physical-addresses' }
        @{ Name = 'Amazon S3 Client Secret Access Key'; DocSlug = 'sit-defn-amazon-s3-client-secret-access-key' }
        @{ Name = 'Argentina national identity (DNI) number'; DocSlug = 'sit-defn-argentina-national-identity-numbers' }
        @{ Name = 'Argentina Unique Tax Identification Key (CUIT/CUIL)'; DocSlug = 'sit-defn-argentina-unique-tax-identification-key' }
        @{ Name = 'ASP.NET machine Key'; DocSlug = 'sit-defn-asp-net-machine-key' }
        @{ Name = 'Australia bank account number'; DocSlug = 'sit-defn-australia-bank-account-number' }
        @{ Name = 'Australian Business Number'; DocSlug = 'sit-defn-australia-business-number' }
        @{ Name = 'Australian Company Number'; DocSlug = 'sit-defn-australia-business-number' }
        @{ Name = "Australia Driver's License Number"; DocSlug = 'sit-defn-australia-drivers-license-number' }
        @{ Name = 'Australia medical account number'; DocSlug = 'sit-defn-australia-medical-account-number' }
        @{ Name = 'Australia passport number'; DocSlug = 'sit-defn-australia-passport-number' }
        @{ Name = 'Australia physical addresses'; DocSlug = 'sit-defn-australia-physical-addresses' }
        @{ Name = 'Australia tax file number'; DocSlug = 'sit-defn-australia-tax-file-number' }
        @{ Name = "Austria Driver's License Number"; DocSlug = 'sit-defn-austria-drivers-license-number' }
        @{ Name = 'Austria identity card'; DocSlug = 'sit-defn-austria-identity-card' }
        @{ Name = 'Austria passport number'; DocSlug = 'sit-defn-austria-passport-number' }
        @{ Name = 'Austria physical addresses'; DocSlug = 'sit-defn-austria-physical-addresses' }
        @{ Name = 'Austria social security number'; DocSlug = 'sit-defn-austria-social-security-number' }
        @{ Name = 'Austria tax identification number'; DocSlug = 'sit-defn-austria-tax-identification-number' }
        @{ Name = 'Austria Value Added Tax (VAT) Number'; DocSlug = 'sit-defn-austria-value-added-tax' }
        @{ Name = 'Azure App Service deployment password'; DocSlug = 'sit-defn-azure-app-service-deployment-password' }
        @{ Name = 'Azure Batch shared access key'; DocSlug = 'sit-defn-azure-batch-shared-access-key' }
        @{ Name = 'Azure Bot Framework secret key'; DocSlug = 'sit-defn-azure-bot-framework-secret-key' }
        @{ Name = 'Azure Bot service app secret'; DocSlug = 'sit-defn-azure-bot-service-app-secret' }
        @{ Name = 'Azure Cognitive Search API key'; DocSlug = 'sit-defn-azure-cognitive-search-api-key' }
        @{ Name = 'Azure Cognitive Service key'; DocSlug = 'sit-defn-azure-cognitive-service-key' }
        @{ Name = 'Azure Container Registry access key'; DocSlug = 'sit-defn-azure-container-registry-access-key' }
        @{ Name = 'Azure Cosmos DB account access key'; DocSlug = 'sit-defn-azure-cosmos-db-account-access-key' }
        @{ Name = 'Azure Databricks personal access token'; DocSlug = 'sit-defn-azure-databricks-personal-access-token' }
        @{ Name = 'Azure DevOps app secret'; DocSlug = 'sit-defn-azure-devops-app-secret' }
        @{ Name = 'Azure DevOps personal access token'; DocSlug = 'sit-defn-azure-devops-personal-access-token' }
        @{ Name = 'Azure DocumentDB auth key'; DocSlug = 'sit-defn-azure-document-db-auth-key' }
        @{ Name = 'Azure EventGrid access key'; DocSlug = 'sit-defn-azure-eventgrid-access-key' }
        @{ Name = 'Azure Function Master / API key'; DocSlug = 'sit-defn-azure-function-master-api-key' }
        @{ Name = 'Azure IAAS database connection string and Azure SQL connection string'; DocSlug = 'sit-defn-azure-iaas-database-connection-string-azure-sql-connection-string' }
        @{ Name = 'Azure IoT connection string'; DocSlug = 'sit-defn-azure-iot-connection-string' }
        @{ Name = 'Azure IoT shared access key'; DocSlug = 'sit-defn-azure-iot-shared-access-key' }
        @{ Name = 'Azure Logic app shared access signature'; DocSlug = 'sit-defn-azure-logic-app-shared-access-signature' }
        @{ Name = 'Azure Machine Learning web service API key'; DocSlug = 'sit-defn-azure-machine-learning-web-service-api-key' }
        @{ Name = 'Azure Maps subscription key'; DocSlug = 'sit-defn-azure-maps-subscription-key' }
        @{ Name = 'Azure publish setting password'; DocSlug = 'sit-defn-azure-publish-setting-password' }
        @{ Name = 'Azure Redis cache connection string'; DocSlug = 'sit-defn-azure-redis-cache-connection-string' }
        @{ Name = 'Azure Redis cache connection string password'; DocSlug = 'sit-defn-azure-redis-cache-connection-string-password' }
        @{ Name = 'Azure SAS'; DocSlug = 'sit-defn-azure-sas' }
        @{ Name = 'Azure service bus connection string'; DocSlug = 'sit-defn-azure-service-bus-connection-string' }
        @{ Name = 'Azure service bus shared access signature'; DocSlug = 'sit-defn-azure-service-bus-shared-access-signature' }
        @{ Name = 'Azure Shared Access key / Web Hook token'; DocSlug = 'sit-defn-azure-shared-access-key-web-hook-token' }
        @{ Name = 'Azure SignalR access key'; DocSlug = 'sit-defn-azure-signalr-access-key' }
        @{ Name = 'Azure SQL connection string'; DocSlug = 'sit-defn-azure-sql-connection-string' }
        @{ Name = 'Azure storage account access key'; DocSlug = 'sit-defn-azure-storage-account-access-key' }
        @{ Name = 'Azure storage account key'; DocSlug = 'sit-defn-azure-storage-account-key' }
        @{ Name = 'Azure Storage account key (generic)'; DocSlug = 'sit-defn-azure-storage-account-key-generic' }
        @{ Name = 'Azure Storage account shared access signature'; DocSlug = 'sit-defn-azure-storage-account-shared-access-signature' }
        @{ Name = 'Azure Storage account shared access signature for high risk resources'; DocSlug = 'sit-defn-azure-storage-account-shared-access-signature-high-risk-resources' }
        @{ Name = 'Azure subscription management certificate'; DocSlug = 'sit-defn-azure-subscription-management-certificate' }
        @{ Name = "Belgium driver's license number"; DocSlug = 'sit-defn-belgium-drivers-license-number' }
        @{ Name = 'Belgium national number'; DocSlug = 'sit-defn-belgium-national-number' }
        @{ Name = 'Belgium passport number'; DocSlug = 'sit-defn-belgium-passport-number' }
        @{ Name = 'Belgium physical addresses'; DocSlug = 'sit-defn-belgium-physical-addresses' }
        @{ Name = 'Belgium value added tax number'; DocSlug = 'sit-defn-belgium-value-added-tax-number' }
        @{ Name = 'Blood test terms'; DocSlug = 'sit-defn-blood-test-terms' }
        @{ Name = 'Brand medication names'; DocSlug = 'sit-defn-brand-medication-names' }
        @{ Name = 'Brazil CPF number'; DocSlug = 'sit-defn-brazil-cpf-number' }
        @{ Name = 'Brazil legal entity number (CNPJ)'; DocSlug = 'sit-defn-brazil-legal-entity-number' }
        @{ Name = 'Brazil National ID Card (RG)'; DocSlug = 'sit-defn-brazil-national-identification-card' }
        @{ Name = 'Brazil physical addresses'; DocSlug = 'sit-defn-brazil-physical-addresses' }
        @{ Name = "Bulgaria driver's license number"; DocSlug = 'sit-defn-bulgaria-drivers-license-number' }
        @{ Name = 'Bulgaria passport number'; DocSlug = 'sit-defn-bulgaria-passport-number' }
        @{ Name = 'Bulgaria physical addresses'; DocSlug = 'sit-defn-bulgaria-physical-addresses' }
        @{ Name = 'Bulgaria uniform civil number'; DocSlug = 'sit-defn-bulgaria-uniform-civil-number' }
        @{ Name = 'Canada bank account number'; DocSlug = 'sit-defn-canada-bank-account-number' }
        @{ Name = "Canada driver's license number"; DocSlug = 'sit-defn-canada-drivers-license-number' }
        @{ Name = 'Canada health service number'; DocSlug = 'sit-defn-canada-health-service-number' }
        @{ Name = 'Canada passport number'; DocSlug = 'sit-defn-canada-passport-number' }
        @{ Name = 'Canada personal health identification number (PHIN)'; DocSlug = 'sit-defn-canada-personal-health-identification-number' }
        @{ Name = 'Canada physical addresses'; DocSlug = 'sit-defn-canada-physical-addresses' }
        @{ Name = 'Canada social insurance number'; DocSlug = 'sit-defn-canada-social-insurance-number' }
        @{ Name = 'Chile identity card number'; DocSlug = 'sit-defn-chile-identity-card-number' }
        @{ Name = 'China resident identity card (PRC) number'; DocSlug = 'sit-defn-china-resident-identity-card-number' }
        @{ Name = 'China physical addresses'; DocSlug = 'sit-defn-china-physical-addresses' }
        @{ Name = 'Client secret / API key'; DocSlug = 'sit-defn-client-secret-api-key' }
        @{ Name = 'Credit card number'; DocSlug = 'sit-defn-credit-card-number' }
        @{ Name = 'Colombia national ID'; DocSlug = 'sit-defn-colombia-national-id' }
        @{ Name = 'Colombia tax identification number'; DocSlug = 'sit-defn-colombia-tax-identification-number' }
        @{ Name = "Croatia driver's license number"; DocSlug = 'sit-defn-croatia-drivers-license-number' }
        @{ Name = 'Croatia identity card number'; DocSlug = 'sit-defn-croatia-identity-card-number' }
        @{ Name = 'Croatia passport number'; DocSlug = 'sit-defn-croatia-passport-number' }
        @{ Name = 'Croatia personal identification (OIB) number'; DocSlug = 'sit-defn-croatia-personal-identification-number' }
        @{ Name = 'Croatia physical addresses'; DocSlug = 'sit-defn-croatia-physical-addresses' }
        @{ Name = "Cyprus Driver's License Number"; DocSlug = 'sit-defn-cyprus-drivers-license-number' }
        @{ Name = 'Cyprus identity card'; DocSlug = 'sit-defn-cyprus-identity-card' }
        @{ Name = 'Cyprus passport number'; DocSlug = 'sit-defn-cyprus-passport-number' }
        @{ Name = 'Cyprus physical addresses'; DocSlug = 'sit-defn-cyprus-physical-addresses' }
        @{ Name = 'Cyprus tax identification number'; DocSlug = 'sit-defn-cyprus-tax-identification-number' }
        @{ Name = "Czech driver's license number"; DocSlug = 'sit-defn-czech-drivers-license-number' }
        @{ Name = 'Czech passport number'; DocSlug = 'sit-defn-czech-passport-number' }
        @{ Name = 'Czech personal identity number'; DocSlug = 'sit-defn-czech-personal-identity-number' }
        @{ Name = 'Czech Republic physical addresses'; DocSlug = 'sit-defn-czech-republic-physical-addresses' }
        @{ Name = "Denmark driver's license number"; DocSlug = 'sit-defn-denmark-drivers-license-number' }
        @{ Name = 'Denmark passport number'; DocSlug = 'sit-defn-denmark-passport-number' }
        @{ Name = 'Denmark personal identification number'; DocSlug = 'sit-defn-denmark-personal-identification-number' }
        @{ Name = 'Denmark physical addresses'; DocSlug = 'sit-defn-denmark-physical-addresses' }
        @{ Name = 'Diseases'; DocSlug = 'sit-defn-diseases' }
        @{ Name = 'Drug Enforcement Agency (DEA) number'; DocSlug = 'sit-defn-drug-enforcement-agency-number' }
        @{ Name = 'Ecuador Unique Identification Number'; DocSlug = 'sit-defn-ecuador-unique-identification-number' }
        @{ Name = "Estonia driver's license number"; DocSlug = 'sit-defn-estonia-drivers-license-number' }
        @{ Name = 'Estonia passport number'; DocSlug = 'sit-defn-estonia-passport-number' }
        @{ Name = 'Estonia Personal Identification Code'; DocSlug = 'sit-defn-estonia-personal-identification-code' }
        @{ Name = 'Estonia physical addresses'; DocSlug = 'sit-defn-estonia-physical-addresses' }
        @{ Name = 'EU debit card number'; DocSlug = 'sit-defn-eu-debit-card-number' }
        @{ Name = "EU driver's license number"; DocSlug = 'sit-defn-eu-drivers-license-number' }
        @{ Name = 'EU national identification number'; DocSlug = 'sit-defn-eu-national-identification-number' }
        @{ Name = 'EU passport number'; DocSlug = 'sit-defn-eu-passport-number' }
        @{ Name = 'EU Social Security Number (SSN) or Equivalent ID'; DocSlug = 'sit-defn-eu-social-security-number-equivalent-identification' }
        @{ Name = 'EU Tax Identification Number (TIN)'; DocSlug = 'sit-defn-eu-tax-identification-number' }
        @{ Name = "Finland driver's license number"; DocSlug = 'sit-defn-finland-drivers-license-number' }
        @{ Name = 'Finland European health insurance number'; DocSlug = 'sit-defn-finland-european-health-insurance-number' }
        @{ Name = 'Finland national ID'; DocSlug = 'sit-defn-finland-national-id' }
        @{ Name = 'Finland passport number'; DocSlug = 'sit-defn-finland-passport-number' }
        @{ Name = 'Finland physical addresses'; DocSlug = 'sit-defn-finland-physical-addresses' }
        @{ Name = "France driver's license number"; DocSlug = 'sit-defn-france-drivers-license-number' }
        @{ Name = 'France health insurance number'; DocSlug = 'sit-defn-france-health-insurance-number' }
        @{ Name = 'France national id card (CNI)'; DocSlug = 'sit-defn-france-national-id-card' }
        @{ Name = 'France passport number'; DocSlug = 'sit-defn-france-passport-number' }
        @{ Name = 'France physical addresses'; DocSlug = 'sit-defn-france-physical-addresses' }
        @{ Name = 'France social security number (INSEE)'; DocSlug = 'sit-defn-france-social-security-number' }
        @{ Name = 'France Tax Identification Number (numero SPI.)'; DocSlug = 'sit-defn-france-tax-identification-number' }
        @{ Name = 'France value added tax number'; DocSlug = 'sit-defn-france-value-added-tax-number' }
        @{ Name = 'General password'; DocSlug = 'sit-defn-general-password' }
        @{ Name = 'General Symmetric key'; DocSlug = 'sit-defn-general-symmetric-key' }
        @{ Name = 'Generic medication names'; DocSlug = 'sit-defn-generic-medication-names' }
        @{ Name = "German Driver's License Number"; DocSlug = 'sit-defn-germany-drivers-license-number' }
        @{ Name = 'Germany identity card number'; DocSlug = 'sit-defn-germany-identity-card-number' }
        @{ Name = 'German Passport Number'; DocSlug = 'sit-defn-germany-passport-number' }
        @{ Name = 'Germany physical addresses'; DocSlug = 'sit-defn-germany-physical-addresses' }
        @{ Name = 'Germany tax identification number'; DocSlug = 'sit-defn-germany-tax-identification-number' }
        @{ Name = 'Germany value added tax number'; DocSlug = 'sit-defn-germany-value-added-tax-number' }
        @{ Name = 'GitHub Personal Access Token'; DocSlug = 'sit-defn-github-personal-access-token' }
        @{ Name = 'Google API key'; DocSlug = 'sit-defn-google-api-key' }
        @{ Name = 'Greenland physical addresses'; DocSlug = 'sit-defn-greenland-physical-addresses' }
        @{ Name = "Greece driver's license number"; DocSlug = 'sit-defn-greece-drivers-license-number' }
        @{ Name = 'Greece national ID card'; DocSlug = 'sit-defn-greece-national-id-card' }
        @{ Name = 'Greece passport number'; DocSlug = 'sit-defn-greece-passport-number' }
        @{ Name = 'Greece physical addresses'; DocSlug = 'sit-defn-greece-physical-addresses' }
        @{ Name = 'Greece Social Security Number (AMKA)'; DocSlug = 'sit-defn-greece-social-security-number' }
        @{ Name = 'Greek Tax Identification Number'; DocSlug = 'sit-defn-greece-tax-identification-number' }
        @{ Name = 'Hong Kong identity card (HKID) number'; DocSlug = 'sit-defn-hong-kong-identity-card-number' }
        @{ Name = 'Http authorization header'; DocSlug = 'sit-defn-http-authorization-header' }
        @{ Name = "Hungary driver's license number"; DocSlug = 'sit-defn-hungary-drivers-license-number' }
        @{ Name = 'Hungary passport number'; DocSlug = 'sit-defn-hungary-passport-number' }
        @{ Name = 'Hungary personal identification number'; DocSlug = 'sit-defn-hungary-personal-identification-number' }
        @{ Name = 'Hungary physical addresses'; DocSlug = 'sit-defn-hungary-physical-addresses' }
        @{ Name = 'Hungarian Social Security Number (TAJ)'; DocSlug = 'sit-defn-hungary-social-security-number' }
        @{ Name = 'Hungary tax identification number'; DocSlug = 'sit-defn-hungary-tax-identification-number' }
        @{ Name = 'Hungarian Value Added Tax Number'; DocSlug = 'sit-defn-hungary-value-added-tax-number' }
        @{ Name = 'Iceland physical addresses'; DocSlug = 'sit-defn-iceland-physical-addresses' }
        @{ Name = 'Impairments Listed In The U.S. Disability Evaluation Under Social Security'; DocSlug = 'sit-defn-impairments-us-disability-evaluation-under-social-security' }
        @{ Name = "India driver's License Number"; DocSlug = 'sit-defn-india-drivers-license-number' }
        @{ Name = 'India GST Number'; DocSlug = 'sit-defn-india-gst-number' }
        @{ Name = 'India permanent account number (PAN)'; DocSlug = 'sit-defn-india-permanent-account-number' }
        @{ Name = 'India unique identification (Aadhaar) number'; DocSlug = 'sit-defn-india-unique-identification-number' }
        @{ Name = 'India Voter Id Card'; DocSlug = 'sit-defn-india-voter-id-card' }
        @{ Name = 'Indonesia Drivers License Number'; DocSlug = 'sit-defn-indonesia-drivers-license-number' }
        @{ Name = 'Indonesia identity card (KTP) number'; DocSlug = 'sit-defn-indonesia-identity-card-number' }
        @{ Name = 'Indonesia passport number'; DocSlug = 'sit-defn-indonesia-passport-number' }
        @{ Name = 'International banking account number (IBAN)'; DocSlug = 'sit-defn-international-banking-account-number' }
        @{ Name = 'International classification of diseases (ICD-10-CM)'; DocSlug = 'sit-defn-international-classification-of-diseases-icd-10-cm' }
        @{ Name = 'International classification of diseases (ICD-9-CM)'; DocSlug = 'sit-defn-international-classification-of-diseases-icd-9-cm' }
        @{ Name = 'IP address'; DocSlug = 'sit-defn-ip-address' }
        @{ Name = 'IP Address v4'; DocSlug = 'sit-defn-ip-address-v4' }
        @{ Name = 'IP Address v6'; DocSlug = 'sit-defn-ip-address-v6' }
        @{ Name = "Ireland driver's license number"; DocSlug = 'sit-defn-ireland-drivers-license-number' }
        @{ Name = 'Ireland passport number'; DocSlug = 'sit-defn-ireland-passport-number' }
        @{ Name = 'Ireland personal public service (PPS) number'; DocSlug = 'sit-defn-ireland-personal-public-service-number' }
        @{ Name = 'Ireland physical addresses'; DocSlug = 'sit-defn-ireland-physical-addresses' }
        @{ Name = 'Israel bank account number'; DocSlug = 'sit-defn-israel-bank-account-number' }
        @{ Name = 'Israel National ID'; DocSlug = 'sit-defn-israel-national-identification-number' }
        @{ Name = "Italy driver's license number"; DocSlug = 'sit-defn-italy-drivers-license-number' }
        @{ Name = 'Italy fiscal code'; DocSlug = 'sit-defn-italy-fiscal-code' }
        @{ Name = 'Italy passport number'; DocSlug = 'sit-defn-italy-passport-number' }
        @{ Name = 'Italy physical addresses'; DocSlug = 'sit-defn-italy-physical-addresses' }
        @{ Name = 'Italy value added tax number'; DocSlug = 'sit-defn-italy-value-added-tax-number' }
        @{ Name = 'Japan bank account number'; DocSlug = 'sit-defn-japan-bank-account-number' }
        @{ Name = "Japan driver's license number"; DocSlug = 'sit-defn-japan-drivers-license-number' }
        @{ Name = 'Japanese My Number Corporate'; DocSlug = 'sit-defn-japan-my-number-corporate' }
        @{ Name = 'Japanese My Number Personal'; DocSlug = 'sit-defn-japan-my-number-personal' }
        @{ Name = 'Japan passport number'; DocSlug = 'sit-defn-japan-passport-number' }
        @{ Name = 'Japan physical addresses'; DocSlug = 'sit-defn-japan-physical-addresses' }
        @{ Name = 'Japanese Residence Card Number'; DocSlug = 'sit-defn-japan-residence-card-number' }
        @{ Name = 'Japan resident registration number'; DocSlug = 'sit-defn-japan-resident-registration-number' }
        @{ Name = 'Japan social insurance number (SIN)'; DocSlug = 'sit-defn-japan-social-insurance-number' }
        @{ Name = 'Lab test terms'; DocSlug = 'sit-defn-lab-test-terms' }
        @{ Name = "Latvia driver's license number"; DocSlug = 'sit-defn-latvia-drivers-license-number' }
        @{ Name = 'Latvia passport number'; DocSlug = 'sit-defn-latvia-passport-number' }
        @{ Name = 'Latvia personal code'; DocSlug = 'sit-defn-latvia-personal-code' }
        @{ Name = 'Latvia physical addresses'; DocSlug = 'sit-defn-latvia-physical-addresses' }
        @{ Name = 'Liechtenstein physical addresses'; DocSlug = 'sit-defn-liechtenstein-physical-addresses' }
        @{ Name = 'Lifestyles that relate to medical conditions'; DocSlug = 'sit-defn-lifestyles-relate-to-medical-conditions' }
        @{ Name = "Lithuania driver's license number"; DocSlug = 'sit-defn-lithuania-drivers-license-number' }
        @{ Name = 'Lithuania passport number'; DocSlug = 'sit-defn-lithuania-passport-number' }
        @{ Name = 'Lithuania personal code'; DocSlug = 'sit-defn-lithuania-personal-code' }
        @{ Name = 'Lithuania physical addresses'; DocSlug = 'sit-defn-lithuania-physical-addresses' }
        @{ Name = "Luxembourg Driver's License Number"; DocSlug = 'sit-defn-luxemburg-drivers-license-number' }
        @{ Name = 'Luxembourg National Identification Number (Natural persons)'; DocSlug = 'sit-defn-luxemburg-national-identification-number-natural-persons' }
        @{ Name = 'Luxembourg National Identification Number (Non-natural persons)'; DocSlug = 'sit-defn-luxemburg-national-identification-number-non-natural-persons' }
        @{ Name = 'Luxembourg Passport Number'; DocSlug = 'sit-defn-luxemburg-passport-number' }
        @{ Name = 'Luxembourg Physical Addresses'; DocSlug = 'sit-defn-luxemburg-physical-addresses' }
        @{ Name = 'Malaysia Identity Card Number'; DocSlug = 'sit-defn-malaysia-identification-card-number' }
        @{ Name = 'Malaysia passport number'; DocSlug = 'sit-defn-malaysia-passport-number' }
        @{ Name = "Malta driver's license number"; DocSlug = 'sit-defn-malta-drivers-license-number' }
        @{ Name = 'Malta identity card number'; DocSlug = 'sit-defn-malta-identity-card-number' }
        @{ Name = 'Malta passport number'; DocSlug = 'sit-defn-malta-passport-number' }
        @{ Name = 'Malta physical addresses'; DocSlug = 'sit-defn-malta-physical-addresses' }
        @{ Name = 'Malta Tax ID Number'; DocSlug = 'sit-defn-malta-tax-identification-number' }
        @{ Name = 'Medical Specialities'; DocSlug = 'sit-defn-medical-specialities' }
        @{ Name = 'Medicare Beneficiary Identifier (MBI) card'; DocSlug = 'sit-defn-medicare-beneficiary-identifier-card' }
        @{ Name = 'Mexico Unique Population Registry Code (CURP)'; DocSlug = 'sit-defn-mexico-unique-population-registry-code' }
        @{ Name = 'Microsoft Bing maps key'; DocSlug = 'sit-defn-microsoft-bing-maps-key' }
        @{ Name = 'Microsoft Entra client access token'; DocSlug = 'sit-defn-azure-ad-client-access-token' }
        @{ Name = 'Microsoft Entra client secret'; DocSlug = 'sit-defn-azure-ad-client-secret' }
        @{ Name = 'Microsoft Entra user Credentials'; DocSlug = 'sit-defn-azure-ad-user-credentials' }
        @{ Name = "Netherlands citizen's service (BSN) number"; DocSlug = 'sit-defn-netherlands-citizens-service-number' }
        @{ Name = "Netherlands driver's license number"; DocSlug = 'sit-defn-netherlands-drivers-license-number' }
        @{ Name = 'Netherlands passport number'; DocSlug = 'sit-defn-netherlands-passport-number' }
        @{ Name = 'Netherlands physical addresses'; DocSlug = 'sit-defn-netherlands-physical-addresses' }
        @{ Name = 'Netherlands tax identification number'; DocSlug = 'sit-defn-netherlands-tax-identification-number' }
        @{ Name = 'Netherlands value added tax number'; DocSlug = 'sit-defn-netherlands-value-added-tax-number' }
        @{ Name = 'New Zealand bank account number'; DocSlug = 'sit-defn-new-zealand-bank-account-number' }
        @{ Name = 'New Zealand Driver License Number'; DocSlug = 'sit-defn-new-zealand-drivers-license-number' }
        @{ Name = 'New Zealand inland revenue number'; DocSlug = 'sit-defn-new-zealand-inland-revenue-number' }
        @{ Name = 'New Zealand ministry of health number'; DocSlug = 'sit-defn-new-zealand-ministry-of-health-number' }
        @{ Name = 'New Zealand physical addresses'; DocSlug = 'sit-defn-new-zealand-physical-addresses' }
        @{ Name = 'New Zealand social welfare number'; DocSlug = 'sit-defn-new-zealand-social-welfare-number' }
        @{ Name = 'Norway Identity Number'; DocSlug = 'sit-defn-norway-identification-number' }
        @{ Name = 'Norway physical addresses'; DocSlug = 'sit-defn-norway-physical-addresses' }
        @{ Name = 'Philippines National ID'; DocSlug = 'sit-defn-philippines-national-identification-number' }
        @{ Name = 'Philippines passport number'; DocSlug = 'sit-defn-philippines-passport-number' }
        @{ Name = 'Philippines Unified Multi-Purpose ID Number'; DocSlug = 'sit-defn-philippines-unified-multi-purpose-identification-number' }
        @{ Name = "Poland driver's license number"; DocSlug = 'sit-defn-poland-drivers-license-number' }
        @{ Name = 'Poland identity card'; DocSlug = 'sit-defn-poland-identity-card' }
        @{ Name = 'Poland national ID (PESEL)'; DocSlug = 'sit-defn-poland-national-id' }
        @{ Name = 'Poland Passport Number'; DocSlug = 'sit-defn-poland-passport-number' }
        @{ Name = 'Poland physical addresses'; DocSlug = 'sit-defn-poland-physical-addresses' }
        @{ Name = 'Poland REGON number'; DocSlug = 'sit-defn-poland-regon-number' }
        @{ Name = 'Poland tax identification number'; DocSlug = 'sit-defn-poland-tax-identification-number' }
        @{ Name = 'Portugal citizen card number'; DocSlug = 'sit-defn-portugal-citizen-card-number' }
        @{ Name = "Portugal driver's license number"; DocSlug = 'sit-defn-portugal-drivers-license-number' }
        @{ Name = 'Portugal passport number'; DocSlug = 'sit-defn-portugal-passport-number' }
        @{ Name = 'Portugal physical addresses'; DocSlug = 'sit-defn-portugal-physical-addresses' }
        @{ Name = 'Portugal tax identification number'; DocSlug = 'sit-defn-portugal-tax-identification-number' }
        @{ Name = 'Qatari ID Card Number'; DocSlug = 'sit-defn-qatari-id-card-number' }
        @{ Name = "Romania driver's license number"; DocSlug = 'sit-defn-romania-drivers-license-number' }
        @{ Name = 'Romania passport number'; DocSlug = 'sit-defn-romania-passport-number' }
        @{ Name = 'Romania personal numeric code (CNP)'; DocSlug = 'sit-defn-romania-personal-numeric-code' }
        @{ Name = 'Romania physical addresses'; DocSlug = 'sit-defn-romania-physical-addresses' }
        @{ Name = 'Russian Passport Number (Domestic)'; DocSlug = 'sit-defn-russia-passport-number-domestic' }
        @{ Name = 'Russian Passport Number (International)'; DocSlug = 'sit-defn-russia-passport-number-international' }
        @{ Name = 'Russia physical addresses'; DocSlug = 'sit-defn-russia-physical-addresses' }
        @{ Name = 'Russia taxpayer identification number'; DocSlug = 'sit-defn-russia-taxpayer-identification-number' }
        @{ Name = 'Saudi Arabia National ID'; DocSlug = 'sit-defn-saudi-arabia-national-id' }
        @{ Name = "Singapore driver's license number"; DocSlug = 'sit-defn-singapore-drivers-license-number' }
        @{ Name = 'Singapore passport number'; DocSlug = 'sit-defn-singapore-passport-number' }
        @{ Name = 'Singapore national registration identity card (NRIC) number'; DocSlug = 'sit-defn-singapore-national-registration-identity-card-number' }
        @{ Name = 'Singapore physical addresses'; DocSlug = 'sit-defn-singapore-physical-addresses' }
        @{ Name = 'Slack access token'; DocSlug = 'sit-defn-slack-access-token' }
        @{ Name = "Slovakia driver's license number"; DocSlug = 'sit-defn-slovakia-drivers-license-number' }
        @{ Name = 'Slovakia passport number'; DocSlug = 'sit-defn-slovakia-passport-number' }
        @{ Name = 'Slovakia personal number'; DocSlug = 'sit-defn-slovakia-personal-number' }
        @{ Name = 'Slovakia physical addresses'; DocSlug = 'sit-defn-slovakia-physical-addresses' }
        @{ Name = "Slovenia driver's license number"; DocSlug = 'sit-defn-slovenia-drivers-license-number' }
        @{ Name = 'Slovenia passport number'; DocSlug = 'sit-defn-slovenia-passport-number' }
        @{ Name = 'Slovenia physical addresses'; DocSlug = 'sit-defn-slovenia-physical-addresses' }
        @{ Name = 'Slovenia tax identification number'; DocSlug = 'sit-defn-slovenia-tax-identification-number' }
        @{ Name = 'Slovenia Unique Master Citizen Number'; DocSlug = 'sit-defn-slovenia-unique-master-citizen-number' }
        @{ Name = 'South Africa identification number'; DocSlug = 'sit-defn-south-africa-identification-number' }
        @{ Name = 'South Africa physical addresses'; DocSlug = 'sit-defn-south-africa-physical-addresses' }
        @{ Name = "South Korea driver's license number"; DocSlug = 'sit-defn-south-korea-drivers-license-number' }
        @{ Name = 'South Korea passport number'; DocSlug = 'sit-defn-south-korea-passport-number' }
        @{ Name = 'South Korea resident registration number'; DocSlug = 'sit-defn-south-korea-resident-registration-number' }
        @{ Name = 'Spain DNI'; DocSlug = 'sit-defn-spain-dni' }
        @{ Name = "Spain driver's license number"; DocSlug = 'sit-defn-spain-drivers-license-number' }
        @{ Name = 'Spain passport number'; DocSlug = 'sit-defn-spain-passport-number' }
        @{ Name = 'Spain physical addresses'; DocSlug = 'sit-defn-spain-physical-addresses' }
        @{ Name = 'Spain social security number (SSN)'; DocSlug = 'sit-defn-spain-social-security-number' }
        @{ Name = 'Spain tax identification number'; DocSlug = 'sit-defn-spain-tax-identification-number' }
        @{ Name = 'SQL Server connection string'; DocSlug = 'sit-defn-sql-server-connection-string' }
        @{ Name = 'Surgical procedures'; DocSlug = 'sit-defn-surgical-procedures' }
        @{ Name = "Sweden driver's license number"; DocSlug = 'sit-defn-sweden-drivers-license-number' }
        @{ Name = 'Sweden national ID'; DocSlug = 'sit-defn-sweden-national-id' }
        @{ Name = 'Sweden passport number'; DocSlug = 'sit-defn-sweden-passport-number' }
        @{ Name = 'Sweden physical addresses'; DocSlug = 'sit-defn-sweden-physical-addresses' }
        @{ Name = 'Sweden tax identification number'; DocSlug = 'sit-defn-sweden-tax-identification-number' }
        @{ Name = 'SWIFT code'; DocSlug = 'sit-defn-swift-code' }
        @{ Name = 'Switzerland physical addresses'; DocSlug = 'sit-defn-switzerland-physical-addresses' }
        @{ Name = 'Swiss Social Security Number AHV'; DocSlug = 'sit-defn-switzerland-ssn-ahv-number' }
        @{ Name = 'Taiwan National ID'; DocSlug = 'sit-defn-taiwan-national-identification-number' }
        @{ Name = 'Taiwan passport number'; DocSlug = 'sit-defn-taiwan-passport-number' }
        @{ Name = 'Taiwan Resident Certificate (ARC/TARC)'; DocSlug = 'sit-defn-taiwan-resident-certificate-number' }
        @{ Name = 'Thai population identification code'; DocSlug = 'sit-defn-thai-population-identification-code' }
        @{ Name = 'Turkey national identification number'; DocSlug = 'sit-defn-turkey-national-identification-number' }
        @{ Name = 'Turkey physical addresses'; DocSlug = 'sit-defn-turkey-physical-addresses' }
        @{ Name = 'Types of medication'; DocSlug = 'sit-defn-types-of-medication' }
        @{ Name = 'U.A.E. identity card number'; DocSlug = 'sit-defn-uae-identity-card-number' }
        @{ Name = 'U.A.E. passport number'; DocSlug = 'sit-defn-uae-passport-number' }
        @{ Name = "U.K. driver's license number"; DocSlug = 'sit-defn-uk-drivers-license-number' }
        @{ Name = 'U.K. electoral roll number'; DocSlug = 'sit-defn-uk-electoral-roll-number' }
        @{ Name = 'U.K. national health service number'; DocSlug = 'sit-defn-uk-national-health-service-number' }
        @{ Name = 'U.K. national insurance number (NINO)'; DocSlug = 'sit-defn-uk-national-insurance-number' }
        @{ Name = 'U.K. physical addresses'; DocSlug = 'sit-defn-uk-physical-addresses' }
        @{ Name = 'U.K. Unique Taxpayer Reference Number'; DocSlug = 'sit-defn-uk-unique-taxpayer-reference-number' }
        @{ Name = 'U.S. bank account number'; DocSlug = 'sit-defn-us-bank-account-number' }
        @{ Name = "U.S. driver's license number"; DocSlug = 'sit-defn-us-drivers-license-number' }
        @{ Name = 'U.S. individual taxpayer identification number (ITIN)'; DocSlug = 'sit-defn-us-individual-taxpayer-identification-number' }
        @{ Name = 'U.S. physical addresses'; DocSlug = 'sit-defn-us-physical-addresses' }
        @{ Name = 'U.S. social security number (SSN)'; DocSlug = 'sit-defn-us-social-security-number' }
        @{ Name = 'U.S./U.K. passport number'; DocSlug = 'sit-defn-us-uk-passport-number' }
        @{ Name = 'Ukraine Passport Number (Domestic)'; DocSlug = 'sit-defn-ukraine-passport-domestic' }
        @{ Name = 'Ukraine Passport Number (International)'; DocSlug = 'sit-defn-ukraine-passport-international' }
        @{ Name = 'Ukraine physical addresses'; DocSlug = 'sit-defn-ukraine-physical-addresses' }
        @{ Name = 'User login credentials'; DocSlug = 'sit-defn-user-login-credentials' }
        @{ Name = 'X.509 certificate private key'; DocSlug = 'sit-defn-x-509-certificate-private-key' }
    )
}
