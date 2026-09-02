# Test-CopilotAndDLP

Submit an approved synthetic sensitive-data prompt to Microsoft 365 Copilot Chat and capture safe correlation metadata for Microsoft Purview DLP validation.

> [!IMPORTANT]
> A successful API response proves only that the prompt was submitted. It does not prove that a DLP rule matched. Correlate the returned run ID, test user, UTC start time, and conversation ID with the expected Microsoft Purview DLP alert or audit event.

## Requirements

- PowerShell 7.2 or later
- `Microsoft.Graph.Authentication` (installed automatically for the current user if missing)
- A Microsoft 365 Copilot add-on license for the signed-in test user
- Microsoft Graph delegated consent for:
  - `Sites.Read.All`
  - `Mail.Read`
  - `People.Read.All`
  - `OnlineMeetingTranscript.Read.All`
  - `Chat.Read`
  - `ChannelMessage.Read.All`
  - `ExternalItem.Read.All`

The Microsoft 365 Copilot Chat API is a preview Microsoft Graph beta API. It currently supports delegated authentication only; application permissions and client-credential authentication are not supported.

## How the Copilot Chat API works

This module uses the Microsoft Graph PowerShell authentication library, but sends the Copilot requests directly with `Invoke-MgGraphRequest`. A validation run performs the following operations:

1. `Connect-MgGraph` signs in a licensed Microsoft 365 Copilot test user with delegated permissions.
2. `POST https://graph.microsoft.com/beta/copilot/conversations` creates a Copilot conversation and returns its conversation ID.
3. `POST https://graph.microsoft.com/beta/copilot/conversations/{conversation-id}/chat` submits the synthetic test value as prompt text.
4. The module records the run ID, conversation ID, signed-in user, tenant, UTC timestamps, submission status, and a SHA-256 hash of the synthetic value.
5. `Search-CopilotDlpAuditEvent` can later search the Microsoft Purview unified audit log for `CopilotInteraction` records in the corresponding user and time window.

The run ID is included in the prompt as `Test ID: <RunId>`, which provides a unique value for later correlation. The API response only confirms whether Copilot accepted the request. It does not confirm that Microsoft Purview matched a sensitive information type or enforced a DLP rule.

The module uses the synchronous chat endpoint because a DLP validation run needs one completed response rather than streamed output. Web search is disabled on each request by default so prompt-processing behavior can be tested independently.

## Why the permissions are broader than expected

The Copilot Chat API doesn't currently expose a single permission such as `Copilot.Write` for submitting prompts. Instead, it runs in the security context of the signed-in user and requires the delegated read scopes listed above. These scopes allow Copilot's enterprise-grounding service to search the Microsoft 365 data sources that the API supports. They don't grant the module permission to change mail, sites, chats, meetings, or external items.

The effective access is the intersection of both controls:

- The delegated scopes granted to the Microsoft Graph PowerShell client.
- The data the signed-in test user is already authorized to read in Microsoft 365.

For example, `Sites.Read.All` allows the API to read SharePoint content on behalf of the user, but it doesn't let the user bypass existing SharePoint permissions. Even so, these are high-impact tenant-wide delegated scopes and should go through the organization's normal security and consent review.

Use the following safeguards:

- Run tests with a dedicated, licensed test account rather than an administrator account.
- Give the test account access only to controlled test data and test sites.
- Use synthetic sensitive values approved by the organization.
- Grant delegated consent only for the scopes required by the Copilot Chat API.
- Protect the PowerShell token cache, JSONL correlation records, and text logs.
- Review preview API and permission requirements regularly because Microsoft can change them.

### Scheduled and unattended execution

Delegated-only authentication is the main challenge for running this module on a schedule. The Copilot Chat API doesn't support application permissions, managed identities, or client-secret/client-certificate authentication. Therefore, a daemon or scheduled task can't use the usual app-only Microsoft Graph pattern.

The initial sign-in requires a user through Windows Web Account Manager or device-code authentication. A scheduled process might be able to reuse a protected delegated token cache, but token renewal can still require user interaction because of expiration, revocation, multifactor authentication, Conditional Access, or sign-in-frequency policies. Treat any cached-token approach as tenant-specific and don't weaken those policies to make the test unattended.

A practical design is to run the submission under a dedicated test-user context, write the safe correlation record, and run audit correlation later. The correlation job has separate requirements: `Search-CopilotDlpAuditEvent` connects to Exchange Online and requires a role that can read the unified audit log, such as **View-Only Audit Logs** or **Audit Logs**. The submission account and audit-search account don't have to be the same identity.

## Prompt-text tests versus file tests

For a rule that detects an SSN or another sensitive information type in a Copilot prompt, place the approved synthetic value directly in `-TestSensitiveText`. Microsoft Purview DLP evaluates text entered directly into the prompt.

Uploading a file directly in a Copilot prompt is not an equivalent sensitive-information-type test. Microsoft currently documents that DLP can't scan the contents of files uploaded directly into prompts; only the typed prompt text is evaluated for sensitive information types.

The Copilot Chat API can use existing OneDrive and SharePoint files as contextual resources, but that is a different test scenario and this module doesn't currently add file contextual resources to its request. To validate file-processing restrictions, store a test file in a controlled SharePoint or OneDrive location, apply a sensitivity label covered by a Copilot DLP rule, ask Copilot to summarize the file, and verify that its contents were excluded. File exclusion in the Microsoft 365 Copilot and Copilot Chat DLP location is based on sensitivity labels rather than scanning a prompt-uploaded file for an SSN.

See:

- [Microsoft 365 Copilot Chat API overview](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/ai-services/chat/overview)
- [Microsoft Purview DLP for Microsoft 365 Copilot and Copilot Chat](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about)

## Dependency installation

`Test-CopilotAndDLP` checks whether `Microsoft.Graph.Authentication` is installed. If it is missing, the command installs it for the current user (`Install-Module -Scope CurrentUser`) before importing it. Each step is logged to the console. To install it yourself ahead of time instead:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

## Import

From the repository root:

```powershell
Import-Module ./1.0/Test-CopilotAndDLP.psd1 -Force
```

## Examples

Preview the operation without authentication or network calls:

```powershell
Test-CopilotAndDLP `
    -TestSensitiveText '<approved synthetic value>' `
    -WhatIf
```

Submit with Windows Web Account Manager authentication:

```powershell
Test-CopilotAndDLP `
    -TenantId 'contoso.onmicrosoft.com' `
    -TestSensitiveText '<approved synthetic value>' `
    -Confirm:$false `
    -Verbose
```

Use device-code authentication when an interactive sign-in window is unavailable:

```powershell
Test-CopilotAndDLP `
    -TenantId 'contoso.onmicrosoft.com' `
    -TestSensitiveText '<approved synthetic value>' `
    -UseDeviceCode `
    -Confirm:$false
```

Web search is disabled by default so prompt-processing DLP behavior can be tested independently. Enable it explicitly only when required:

```powershell
Test-CopilotAndDLP `
    -TestSensitiveText '<approved synthetic value>' `
    -EnableWebSearch `
    -Confirm:$false
```

Test a sensitive information type other than U.S. social security number (SSN) (the default) by pairing the value with a matching corroborative keyword via `-SensitiveInfoTypeLabel`. For example, testing the built-in Credit card number type with a well-known, publicly documented test card number:

```powershell
Test-CopilotAndDLP `
    -TestSensitiveText '4111111111111111' `
    -SensitiveInfoTypeLabel 'Credit card number' `
    -Confirm:$false
```

`-SensitiveInfoTypeLabel` is embedded next to `-TestSensitiveText` in the prompt (for example, `Credit card number: 4111111111111111`) because many built-in SITs raise match confidence based on proximity to a corroborative keyword, not the pattern alone. Using the default label (`U.S. social security number (SSN)`) with a credit-card-shaped value, or vice versa, can reduce or prevent a match.

`-SensitiveInfoTypeLabel` only accepts an exact name (case-insensitive) from the bundled catalog — it's enforced with `ValidateSet`, so unlisted values are rejected at parameter binding, and the value tab-completes.

## Testing any built-in sensitive information type

The module bundles the full Microsoft Purview [built-in sensitive information type catalog](https://learn.microsoft.com/purview/sit-sensitive-information-type-entity-definitions) (300+ entity definitions) so you can find the correct name and reference documentation for any type you want to validate:

```powershell
# Browse or search the catalog
Get-CopilotDlpSensitiveInfoType
Get-CopilotDlpSensitiveInfoType -Name '*passport*'

# Look up the documentation link for a specific type's detection pattern
(Get-CopilotDlpSensitiveInfoType -Name 'International banking account number (IBAN)').DocUrl
```

`-SensitiveInfoTypeLabel` on `Test-CopilotAndDLP` is validated (`ValidateSet`) and tab-completes against this catalog — only exact catalog names (case-insensitive) are accepted. Workflow for testing a type other than U.S. social security number (SSN) or Credit card number:

1. Run `Get-CopilotDlpSensitiveInfoType -Name '<search term>'` to find the exact SIT name and its Microsoft Learn `DocUrl`.
2. Open `DocUrl` and confirm the pattern/format and any required corroborative keywords for that type.
3. Construct an approved synthetic value matching that pattern (the module does not generate or validate sample values for you — country- and type-specific formats vary too much to safely auto-generate).
4. Run `Test-CopilotAndDLP -TestSensitiveText '<synthetic value>' -SensitiveInfoTypeLabel '<SIT name>' -Confirm:$false`.

This command only helps with discovery (name + reference link); it does not fabricate sample PII, and you're still responsible for using only synthetic values approved by your organization.

## Results and correlation

The command returns a `CopilotDlp.ValidationResult` object with submission status, correlation identifiers, Copilot response text, and any API error. Each attempted submission appends one JSON object to `-ResultPath` (by default, `copilot-dlp-results.jsonl` in the current PowerShell directory).

Each run also appends timestamped progress lines to `-LogPath` (by default, `copilot-dlp.log` in the current PowerShell directory) and echoes the same lines to the console. As with the JSONL file, the synthetic value and Copilot response are never written to this log.

The JSONL record contains:

- Run and conversation identifiers
- UTC start and completion times
- Signed-in account and tenant ID
- Submission status and expected DLP outcome
- SHA-256 hash of the synthetic test value
- Web-search state and API error text

The plaintext synthetic value and Copilot response are not written to the JSONL file.

## Security guidance

1. Use only synthetic values approved by your organization.
2. Never provide a real Social Security number or other personal information.
3. Treat the SHA-256 value as correlation metadata, not as anonymization. Low-entropy inputs can be guessed and hashed.
4. Store the JSONL result in an access-controlled location.
5. Review the generated prompt with `-WhatIf` behavior before submitting, and use a dedicated licensed test account.
6. The command requests broad read scopes required by the preview Copilot Chat API. Review and approve delegated consent through your organization's normal process.

## Submission status

- `Submitted`: the Copilot Chat API returned a response.
- `ApiRejected`: conversation creation or chat submission failed. The command writes safe correlation metadata and returns the error.

Neither status independently confirms whether Microsoft Purview DLP detected or blocked the prompt.

## Correlating with Microsoft Purview

`Test-CopilotAndDLP` only proves that a prompt was submitted. To confirm what Microsoft Purview actually saw, pull corresponding data from the Microsoft Purview / Microsoft 365 compliance side using one or more of the following, keyed on the `TestUser`, `StartedAtUtc`, and `RunId` values returned by the run:

1. **Unified audit log (`CopilotInteraction` records)** – use the included [`Search-CopilotDlpAuditEvent`](docs/Search-CopilotDlpAuditEvent.md) command to search for audited Copilot interactions for the test account around the run's time window:

   ```powershell
   $result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
   $result | Search-CopilotDlpAuditEvent
   ```

   This requires the `ExchangeOnlineManagement` module (installed automatically if missing) and a role with unified audit log read permissions, such as **View-Only Audit Logs** or **Audit Logs**, in Microsoft Purview or Exchange Online. Audit log ingestion can lag by 30 minutes or more — rerun the search later if nothing is returned yet. A matching record confirms the interaction was audited; it does not by itself confirm a DLP match.

2. **Activity explorer in Data Security Posture Management (DSPM) for AI** – shows the actual sensitive-information-type matches and prompt content detected for an interaction. This is currently a Microsoft Purview portal experience; open it and filter by user and time window using the `RunId` embedded in the prompt text (`Test ID: <RunId>`) to confirm the exact interaction.

3. **Alerts** – if the DLP policy is configured to generate an alert on match, check **Alerts** in the Microsoft Purview portal, or query the Microsoft Graph Security API (`/security/alerts_v2`, delegated scope `SecurityAlert.Read.All`) filtered to the same time window and user. The exact alert schema for DLP-for-Copilot matches may vary; verify against current Microsoft Graph documentation before automating this filter.

4. **Content Search / eDiscovery** – can retrieve the full prompt text logged for an interaction when audit alone isn't sufficient.

## Suggested improvements

Areas worth investing in next, roughly in priority order:

- **Automated correlation loop**: extend `Search-CopilotDlpAuditEvent` (or add a new command) to poll on a retry/backoff schedule until a matching audit record appears or a timeout elapses, instead of a single search attempt.
- **DLP alert lookup**: add a command wrapping the Microsoft Graph Security `alerts_v2` API once the DLP-for-Copilot alert schema is confirmed, so a single call can return both the audit record and any associated alert.
- **Retry/backoff on transient Graph errors**: wrap `Invoke-MgGraphRequest` calls in `Test-CopilotAndDLP` with retry logic for `429`/`503` responses.
- **Batch/pipeline support**: allow `Test-CopilotAndDLP` to accept multiple `-TestSensitiveText` values (or a CSV of scenarios) for a full DLP regression suite in one run.
- **CI coverage for `Search-CopilotDlpAuditEvent`**: the current tests mock the Exchange Online call; consider an integration test tier (manually triggered) against a real test tenant.

## Development

Install test dependencies and run validation:

```powershell
Install-Module Pester,PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path ./1.0 -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
Invoke-Pester ./tests
```

Tests mock all Microsoft Graph calls and do not access a live tenant.

Regenerate the command help in `docs/` after changing comment-based help:

```powershell
Install-Module platyPS -Scope CurrentUser
Import-Module ./1.0/Test-CopilotAndDLP.psd1 -Force
Update-MarkdownHelp -Path ./docs/Test-CopilotAndDLP.md -AlphabeticParamsOrder
```

Use `New-MarkdownHelp -Command Test-CopilotAndDLP -OutputFolder ./docs -Force -AlphabeticParamsOrder` instead of `Update-MarkdownHelp` when EXAMPLES or DESCRIPTION prose changed, since `Update-MarkdownHelp` preserves existing hand-authored sections and only refreshes syntax and parameters.

## Module structure

```text
1.0/
|-- Test-CopilotAndDLP.psd1
|-- Test-CopilotAndDLP.psm1
|-- data/
|   `-- SensitiveInfoTypes.psd1
|-- functions/
|   |-- Test-CopilotAndDLP.ps1
|   |-- Search-CopilotDlpAuditEvent.ps1
|   `-- Get-CopilotDlpSensitiveInfoType.ps1
`-- internal/
    `-- functions/
        |-- Get-CopilotResponseText.ps1
        |-- Get-SensitiveInfoTypeCatalog.ps1
        |-- Get-SensitiveTextHash.ps1
        |-- Get-TimeStamp.ps1
        |-- Install-RequiredGraphModule.ps1
        |-- Invoke-UnifiedAuditLogSearch.ps1
        |-- Write-CopilotDlpCorrelationRecord.ps1
        `-- Write-ToLogFile.ps1
tests/
|-- Test-CopilotAndDLP.Tests.ps1
|-- Search-CopilotDlpAuditEvent.Tests.ps1
`-- Get-CopilotDlpSensitiveInfoType.Tests.ps1
docs/
|-- README.md
|-- Test-CopilotAndDLP.md
|-- Search-CopilotDlpAuditEvent.md
`-- Get-CopilotDlpSensitiveInfoType.md
```

Only `Test-CopilotAndDLP`, `Search-CopilotDlpAuditEvent`, and `Get-CopilotDlpSensitiveInfoType` are exported. Helpers are dot-sourced by the module loader and remain private to module scope.

## API documentation

- [Microsoft 365 Copilot Chat API overview](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/ai-services/chat/overview)
- [Audit log activities (Microsoft Purview)](https://learn.microsoft.com/purview/audit-log-activities)
- [Search-UnifiedAuditLog](https://learn.microsoft.com/powershell/module/exchange/search-unifiedauditlog)
- [Sensitive information type entity definitions](https://learn.microsoft.com/purview/sit-sensitive-information-type-entity-definitions)

## License

MIT
