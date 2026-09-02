# Test-CopilotAndDLP

Submit an approved synthetic sensitive-data prompt to Microsoft 365 Copilot Chat and capture safe correlation metadata for Microsoft Purview DLP validation.

> [!IMPORTANT]
> A successful API response proves only that the prompt was submitted. It does not prove that a DLP rule matched. Correlate the returned run ID, test user, UTC start time, and conversation ID with the expected Microsoft Purview DLP alert or audit event.

<br>

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

<br>

## How the Copilot Chat API works

This module uses the Microsoft Graph PowerShell authentication library, but sends the Copilot requests directly with `Invoke-MgGraphRequest`. A validation run performs the following operations:

1. `Connect-MgGraph` signs in a licensed Microsoft 365 Copilot test user with delegated permissions.
2. `POST https://graph.microsoft.com/beta/copilot/conversations` creates a Copilot conversation and returns its conversation ID.
3. `POST https://graph.microsoft.com/beta/copilot/conversations/{conversation-id}/chat` submits the synthetic test value as prompt text.
4. The module records the run ID, conversation ID, signed-in user, tenant, UTC timestamps, submission status, and a SHA-256 hash of the synthetic value.
5. `Search-CopilotDlpAuditEvent` can later search the Microsoft Purview unified audit log for `CopilotInteraction` records and match the submitted `ConversationId` exactly.
6. `Search-CopilotDlpAlert` can retrieve the corresponding Microsoft Data Loss Prevention alert summary from Microsoft Graph.
7. `Search-CopilotDlpDspmEvent` retrieves the corresponding transformed event from DSPM Activity Explorer.
8. `Search-CopilotDlpAndDspmEvidence` runs all three correlation paths and returns one combined result.

The run ID is included in the prompt as `Test ID: <RunId>`, which provides a unique value for later correlation. The API response only confirms whether Copilot accepted the request. It does not confirm that Microsoft Purview matched a sensitive information type or enforced a DLP rule.

The module uses the synchronous chat endpoint because a DLP validation run needs one completed response rather than streamed output. Web search is disabled on each request by default so prompt-processing behavior can be tested independently.

<br>

## Why the permissions are broader than expected

The Copilot Chat API doesn't currently expose a single permission such as `Copilot.Write` for submitting prompts. Instead, it runs in the security context of the signed-in user and requires the delegated read scopes listed above. These scopes allow Copilot's enterprise-grounding service to search the Microsoft 365 data sources that the API supports. They don't grant the module permission to change mail, sites, chats, meetings, or external items.

The effective access is the intersection of both controls:

- The delegated scopes granted to the Microsoft Graph PowerShell client.
- The data the signed-in test user is already authorized to read in Microsoft 365.

For example, `Sites.Read.All` allows the API to read SharePoint content on behalf of the user, but it doesn't let the user bypass existing SharePoint permissions. Even so, these are high-impact tenant-wide delegated scopes and should go through the organization's normal security and consent review.

<br>

Use the following safeguards:

- Run tests with a dedicated, licensed test account rather than an administrator account.
- Give the test account access only to controlled test data and test sites.
- Use synthetic sensitive values approved by the organization.
- Grant delegated consent only for the scopes required by the Copilot Chat API.
- Protect the PowerShell token cache, JSONL correlation records, and text logs.
- Review preview API and permission requirements regularly because Microsoft can change them.

<br>

### Scheduled and unattended execution

Delegated-only authentication is the main challenge for running this module on a schedule. The Copilot Chat API doesn't support application permissions, managed identities, or client-secret/client-certificate authentication. Therefore, a daemon or scheduled task can't use the usual app-only Microsoft Graph pattern.

<br>

The initial sign-in requires a user through Windows Web Account Manager or device-code authentication. A scheduled process might be able to reuse a protected delegated token cache, but token renewal can still require user interaction because of expiration, revocation, multifactor authentication, Conditional Access, or sign-in-frequency policies. Treat any cached-token approach as tenant-specific and don't weaken those policies to make the test unattended.

<br>

A practical design is to run the submission under a dedicated test-user context, write the safe correlation record, and run audit correlation later. The correlation job has separate requirements: `Search-CopilotDlpAuditEvent` connects to Exchange Online and requires a role that can read the unified audit log, such as **View-Only Audit Logs** or **Audit Logs**. The submission account and audit-search account don't have to be the same identity.

<br>

Retrieving DLP alert summaries has another separate permission boundary. `Search-CopilotDlpAlert` uses the Microsoft Graph `security/alerts_v2` endpoint and requests delegated `SecurityAlert.Read.All`. The signed-in account must also have a supported Microsoft Entra role, such as **Security Reader**, **Global Reader**, **Security Operator**, or **Security Administrator**. The command requests read-only alert access and doesn't modify alerts.

<br>

## Prompt-text tests versus file tests

For a rule that detects an SSN or another sensitive information type in a Copilot prompt, place the approved synthetic value directly in `-TestSensitiveText`. Microsoft Purview DLP evaluates text entered directly into the prompt.

<br>

Uploading a file directly in a Copilot prompt is not an equivalent sensitive-information-type test. Microsoft currently documents that DLP can't scan the contents of files uploaded directly into prompts; only the typed prompt text is evaluated for sensitive information types.

<br>

The Copilot Chat API can use existing OneDrive and SharePoint files as contextual resources, but that is a different test scenario and this module doesn't currently add file contextual resources to its request. To validate file-processing restrictions, store a test file in a controlled SharePoint or OneDrive location, apply a sensitivity label covered by a Copilot DLP rule, ask Copilot to summarize the file, and verify that its contents were excluded. File exclusion in the Microsoft 365 Copilot and Copilot Chat DLP location is based on sensitivity labels rather than scanning a prompt-uploaded file for an SSN.

See:

- [Microsoft 365 Copilot Chat API overview](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/ai-services/chat/overview)
- [Microsoft Purview DLP for Microsoft 365 Copilot and Copilot Chat](https://learn.microsoft.com/purview/dlp-microsoft365-copilot-location-learn-about)

<br>

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

<br>

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

<br>

## Results and correlation

The command returns a `CopilotDlp.ValidationResult` object with submission status, correlation identifiers, Copilot response text, and any API error. Each attempted submission appends one JSON object to `-ResultPath` (by default, `copilot-dlp-results.jsonl` in the current PowerShell directory).

<br>

Each run also appends timestamped progress lines to `-LogPath` (by default, `copilot-dlp.log` in the current PowerShell directory) and echoes the same lines to the console. As with the JSONL file, the synthetic value and Copilot response are never written to this log.

The JSONL record contains:

- Run and conversation identifiers
- UTC start and completion times
- Signed-in account and tenant ID
- Submission status and expected DLP outcome
- SHA-256 hash of the synthetic test value
- Web-search state and API error text

The plaintext synthetic value and Copilot response are not written to the JSONL file.

<br>

## Security guidance

1. Use only synthetic values approved by your organization.
2. Never provide a real Social Security number or other personal information.
3. Treat the SHA-256 value as correlation metadata, not as anonymization. Low-entropy inputs can be guessed and hashed.
4. Store the JSONL result in an access-controlled location.
5. Review the generated prompt with `-WhatIf` behavior before submitting, and use a dedicated licensed test account.
6. The command requests broad read scopes required by the preview Copilot Chat API. Review and approve delegated consent through your organization's normal process.

<br>

## Submission status

- `Submitted`: the Copilot Chat API returned a response.
- `ApiRejected`: conversation creation or chat submission failed. The command writes safe correlation metadata and returns the error.
-
- <br>

Neither status independently confirms whether Microsoft Purview DLP detected or blocked the prompt.

<br>

## Correlating with Microsoft Purview

`Test-CopilotAndDLP` only proves that a prompt was submitted. To confirm what Microsoft Purview actually saw, pull corresponding data from the Microsoft Purview / Microsoft 365 compliance side using one or more of the following, keyed on the `TestUser`, `StartedAtUtc`, and `RunId` values returned by the run:

### Which command to use

| Command | Source | Match type | What it returns |
| --- | --- | --- | --- |
| [`Search-CopilotDlpAuditEvent`](docs/Search-CopilotDlpAuditEvent.md) | Microsoft Purview unified audit log (`CopilotInteraction`) | Exact `ConversationId` | Confirms the interaction was audited; `AppHost`, `DLPEvaluationDeferred`/`Reason`. Fastest to ingest (lags ~30+ minutes). |
| [`Search-CopilotDlpDspmEvent`](docs/Search-CopilotDlpDspmEvent.md) | DSPM for AI / Activity Explorer (`Export-ActivityExplorerData`) | Exact `ConversationId` | App and platform detail for the interaction: `AppIdentity`, `AppLocation`, `AppHost`, `DataPlatform`, `LicenseType`, `ThreadId`, `AISystemPlugin`, `DLPEvaluationDeferred`. Lags further behind audit (~60–90+ minutes) and covers only the last 30 days. |
| [`Search-CopilotDlpAlert`](docs/Search-CopilotDlpAlert.md) | Microsoft Graph Security `alerts_v2` | User + activity-window correlation (Graph doesn't expose `ConversationId`) | Alert/incident details: title, status, severity, category, policy title, evidence, recommended actions, portal URLs. |
| [`Search-CopilotDlpAndDspmEvidence`](docs/Search-CopilotDlpAndDspmEvidence.md) | All three of the above | Combines exact and correlated matches | One combined result per conversation (or every JSONL record) with `UnifiedAuditFound`/`DspmEventFound`/`DlpAlertFound`, the complete arrays from each source, and per-source errors. The recommended single entry point. |

For the complete workflow, use one command. It returns exact unified-audit and DSPM matches plus the corresponding Graph DLP alert summary:

```powershell
Search-CopilotDlpAndDspmEvidence `
    -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
    -UserPrincipalName 'admin@contoso.example' `
    -StartDateUtc ([datetime]'2026-09-02T15:00:00Z')
```

To process every saved validation run:

```powershell
$evidence = Search-CopilotDlpAndDspmEvidence `
    -ResultPath './copilot-dlp-results.jsonl'

$evidence | Select-Object `
    ConversationId, UnifiedAuditFound, DspmEventFound, DlpAlertFound
```

Each `CopilotDlp.Evidence` result contains complete arrays in `UnifiedAuditEvents`, `DspmEvents`, and `DlpAlerts`. Unified audit and DSPM are exact `ConversationId` matches. Microsoft Graph `alerts_v2` doesn't expose the event-level conversation ID, so the alert summary uses user-and-activity-window correlation.

<br>

When only `-ConversationId` is supplied, the command first uses the exact unified-audit or DSPM match to derive the test user and activity time, then uses those values to find the corresponding DLP alert. When `-ResultPath` is supplied, it uses the user and time saved with every JSONL record. If DSPM or a DLP alert isn't available, the command identifies the missing source and explains that logging or alert aggregation can lag 60–90 minutes or longer and should be searched again later.

<br>


`-UserPrincipalName` is an account hint and search filter; it isn't a credential or token. With no existing connection, the default is interactive authentication for that account. Device-code authentication occurs only when `-UseDeviceCode` is explicitly supplied. `Search-CopilotDlpAndDspmEvidence -UseDeviceCode` passes that choice to unified-audit and Graph alert authentication.

<br>


When `-UseDeviceCode` is used for Graph DLP alerts, the module intentionally leaves the device-login URL and code visible so sign-in can be completed. Other Graph authentication diagnostics remain reduced to one actionable error. DSPM fields vary by activity type; missing policy, rule, enforcement, or sensitive-information properties are returned as null while the complete source record remains available in `DspmData`.

<br>


When no `-TenantId` is supplied, Graph authentication explicitly uses the `organizations` audience. This prevents the `AADSTS70011` invalid-scope/default-authority failure that can otherwise occur during device-code authentication. Supplying `-TenantId` uses that tenant instead.

Combined evidence searches run the Microsoft Graph DLP-alert step in an isolated PowerShell process. This is required because ExchangeOnlineManagement and Microsoft.Graph.Authentication can load incompatible versions of `Microsoft.Identity.Client` into the same process, causing `Method not found` failures. The isolated process displays any required Graph device code and returns the alert objects to the parent command without exposing or persisting access tokens.

<br>

### Authentication support by endpoint

`-UserPrincipalName` is only an account hint on every endpoint below; it never selects the authentication method or supplies a credential.

| Endpoint | Command | Interactive (UPN hint) | Device code |
| --- | --- | --- | --- |
| Microsoft 365 Copilot Chat (Graph) | `Test-CopilotAndDLP` | Default | `-UseDeviceCode` |
| Unified audit log (Exchange Online) | `Search-CopilotDlpAuditEvent` | Default | `-UseDeviceCode` |
| DLP alerts (Graph `alerts_v2`) | `Search-CopilotDlpAlert` | Default | `-UseDeviceCode` |
| DSPM Activity Explorer (Security & Compliance) | `Search-CopilotDlpDspmEvent` | Only option | Not supported — `Connect-IPPSSession` in the installed `ExchangeOnlineManagement` version has no device-code parameter |

Because Exchange Online and Security & Compliance PowerShell share the same Windows broker (WAM) component, a broken broker on a machine affects both. If interactive sign-in fails with a broker/MSAL error for Exchange, `-UseDeviceCode` is a reliable fallback. DSPM has no such fallback in this module version; a broken broker there can only be fixed by repairing the local WAM/Windows account-broker component, not by a module parameter.

<br>

A PowerShell process that has loaded more than one `ExchangeOnlineManagement` assembly version (for example, after an in-session module update) can fail every Exchange/IPPS call with a generic null-reference-style error regardless of which authentication mode is used. If that happens, close the terminal, open a new PowerShell 7 process, and re-import the module before retrying.

1. **Unified audit log (`CopilotInteraction` records)** – use the included [`Search-CopilotDlpAuditEvent`](docs/Search-CopilotDlpAuditEvent.md) command to search for audited Copilot interactions for the test account around the run's time window:

   ```powershell
   $result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
   $result | Search-CopilotDlpAuditEvent
   ```

   The pipeline passes `ConversationId`, `TestUser`, and `StartedAtUtc`. The audit search uses the user and time window to narrow the query, then returns only a record whose JSON audit payload contains the exact submitted conversation ID. You can also search an individual ID directly:

   ```powershell
   Search-CopilotDlpAuditEvent `
       -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
       -StartDateUtc (Get-Date).ToUniversalTime().AddHours(-2) `
       -UseDeviceCode
   ```

   Or have the command read and correlate every entry in the JSONL result file directly:

   ```powershell
   Search-CopilotDlpAuditEvent `
       -ResultPath './copilot-dlp-results.jsonl' `
       -UseDeviceCode
   ```

   File mode opens one Exchange Online connection, searches every saved `ConversationId`, and returns both `ValidationRecord` (the complete submitted correlation record) and `AuditData` (the complete unified audit payload) for each match.

   In current unified audit records, `ConversationId`, `AppHost`, and DLP evaluation metadata are nested under `CopilotEventData`. The command expands that structure and returns `ConversationId`, `AppHost`, `DLPEvaluationDeferred`, and `DLPEvaluationDeferredReason` as top-level output properties. A nonzero `DLPEvaluationDeferred` value means one or more DLP processing stages were deferred and the audit result isn't yet conclusive.

    This requires the `ExchangeOnlineManagement` module (installed automatically if missing) and a role with unified audit log read permissions, such as **View-Only Audit Logs** or **Audit Logs**, in Microsoft Purview or Exchange Online. Audit log ingestion can lag by 30 minutes or more. A matching record confirms the interaction was audited; it doesn't independently prove a DLP policy match.

    On Windows, the Exchange Online authentication broker can fail in some PowerShell hosts and print an internal MSAL stack trace that the calling module can't suppress. `Search-CopilotDlpAuditEvent` uses default (WAM) interactive sign-in unless you pass `-UseDeviceCode`; if the default sign-in fails with a broker error, run the command again with `-UseDeviceCode` and complete the displayed browser sign-in:

    ```powershell
    Search-CopilotDlpAuditEvent `
         -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
        -StartDateUtc ([datetime]'2026-09-02T15:00:00Z') `
        -UseDeviceCode
    ```

    Open the displayed device-login URL, enter the code, and complete sign-in promptly. If device-code authentication fails or is canceled, the command returns a concise next step. Check Conditional Access and confirm the account has a Purview audit-log role if it continues to fail. `-UseDeviceCode` is opt-in; omit it when the Windows broker is known to work in the current PowerShell host.

    The command first checks `Get-ConnectionInformation` and reuses an existing Exchange Online connection when its state is `Connected`, its token is active, and it matches `-TenantId` when one was supplied. It prompts only when no reusable connection exists. Exchange Online connections are scoped to the current PowerShell process, so authentication in one terminal can't be reused from another terminal. Run `Get-ConnectionInformation | Format-Table ConnectionId,State,TokenStatus,UserPrincipalName,TenantID` in the same terminal to inspect reusable connections.

2. **DLP alert summary (`security/alerts_v2`)** – pipe the same validation result into `Search-CopilotDlpAlert` to retrieve a corresponding Microsoft Data Loss Prevention alert:

    ```powershell
    $result | Search-CopilotDlpAlert
    ```

   To read saved results, make the path relative to the current directory. From the repository root use `./copilot-dlp-results.jsonl`; from inside the `1.0` module folder use `../copilot-dlp-results.jsonl` for the repository-root file:

   ```powershell
   Get-Content '../copilot-dlp-results.jsonl' |
       ConvertFrom-Json |
       Search-CopilotDlpAlert
   ```

    The Graph alert response includes the alert and incident IDs, title, status, severity, policy ID, activity time range, and portal URLs. Microsoft Graph currently doesn't expose the Copilot `ConversationId` in the `alerts_v2` response, even though the Purview portal displays it on the alert's associated event. The command therefore correlates the alert by test user and overlapping activity time and labels the result `CorrelationMethod = UserAndActivityWindow`. Use `Search-CopilotDlpAuditEvent` for the exact `ConversationId` match, then use the alert result for policy and incident details.

    If no alert correlates, the command writes a warning containing the conversation ID, test user, UTC activity time, and candidate-alert count instead of returning silently. This is an inconclusive result until alert ingestion has completed; it can also mean the policy didn't generate an alert or the submission didn't match the rule.

3. **Activity explorer in Data Security Posture Management (DSPM) for AI** – shows the actual sensitive-information-type matches and prompt content detected for an interaction. This is currently a Microsoft Purview portal experience; open it and filter by user and time window using the `RunId` embedded in the prompt text (`Test ID: <RunId>`) to confirm the exact interaction.

   `Search-CopilotDlpDspmEvent` automates the Activity Explorer lookup through `Export-ActivityExplorerData`, paginates the results, and returns only records containing the exact `ConversationId`:

   ```powershell
   Search-CopilotDlpDspmEvent `
       -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
       -UserPrincipalName 'admin@contoso.example' `
       -StartDateUtc ([datetime]'2026-09-02T15:00:00Z')
   ```

    DSPM requires a Security & Compliance PowerShell session and an Activity Explorer role such as **Security Reader**, **Compliance Administrator**, or **Information Protection Reader**. The module requires `ExchangeOnlineManagement` 3.10.1 or later for this path and updates an older installation automatically. If `Export-ActivityExplorerData` is already available in the current PowerShell process, the command reuses that session. Otherwise, it visibly reports that it is connecting and calls `Connect-IPPSSession`. During connection, console and PowerShell streams are isolated so affected versions don't expose internal MSAL call stacks. If the module was updated while an older assembly was loaded, close the terminal and use a new PowerShell 7 terminal before retrying. Activity Explorer can lag unified audit by 60–90 minutes or longer and reports up to 30 days of data. DSPM rejects future dates, so the command clamps its end time to the current UTC time and limits its start time to the last 30 days.

    PowerShell can't unload or replace the Exchange module's .NET assemblies within an existing process. The module therefore never imports a second ExchangeOnlineManagement version over one that is already loaded. Unified-audit searches reuse the loaded version. If DSPM needs a newer version than the loaded assembly, the command returns one restart action rather than an assembly call stack. `Import-Module -Force` doesn't replace already loaded .NET assemblies; a new PowerShell process is required after an ExchangeOnlineManagement update.

4. **Alerts** – if the DLP policy is configured to generate an alert on match, check **Alerts** in the Microsoft Purview portal, or query the Microsoft Graph Security API (`/security/alerts_v2`, delegated scope `SecurityAlert.Read.All`) filtered to the same time window and user. The exact alert schema for DLP-for-Copilot matches may vary; verify against current Microsoft Graph documentation before automating this filter.

5. **Content Search / eDiscovery** – can retrieve the full prompt text logged for an interaction when audit alone isn't sufficient.

## Module structure

```text
1.0/
|-- Test-CopilotAndDLP.psd1
|-- Test-CopilotAndDLP.psm1
|-- data/
|   `-- SensitiveInfoTypes.psd1
|-- en-US/
|   `-- Test-CopilotAndDLP-help.xml
|-- formats/
|   `-- Test-CopilotAndDLP.format.ps1xml
|-- functions/
|   |-- Test-CopilotAndDLP.ps1
|   |-- Search-CopilotDlpAuditEvent.ps1
|   |-- Search-CopilotDlpAlert.ps1
|   |-- Search-CopilotDlpDspmEvent.ps1
|   |-- Search-CopilotDlpAndDspmEvidence.ps1
|   `-- Get-CopilotDlpSensitiveInfoType.ps1
`-- internal/
    `-- functions/
        |-- Get-CopilotResponseText.ps1
        |-- Get-ExchangeConnectionInformation.ps1
        |-- Get-SensitiveInfoTypeCatalog.ps1
        |-- Get-SensitiveTextHash.ps1
        |-- Get-TimeStamp.ps1
        |-- Install-RequiredGraphModule.ps1
        |-- Invoke-ActivityExplorerExport.ps1
        |-- Invoke-CopilotGraphRequestWithRetry.ps1
        |-- Invoke-IsolatedCopilotDlpAlertSearch.ps1
        |-- Invoke-UnifiedAuditLogSearch.ps1
        |-- Resolve-CopilotDlpConversationWindow.ps1
        |-- Write-CopilotDlpCorrelationRecord.ps1
        `-- Write-ToLogFile.ps1
tests/
|-- Test-CopilotAndDLP.Tests.ps1
|-- Search-CopilotDlpAuditEvent.Tests.ps1
|-- Search-CopilotDlpAlert.Tests.ps1
|-- Search-CopilotDlpDspmEvent.Tests.ps1
|-- Search-CopilotDlpAndDspmEvidence.Tests.ps1
|-- Integration.Tests.ps1
`-- Get-CopilotDlpSensitiveInfoType.Tests.ps1
docs/
|-- README.md
|-- Test-CopilotAndDLP.md
|-- Search-CopilotDlpAuditEvent.md
|-- Search-CopilotDlpAlert.md
|-- Search-CopilotDlpDspmEvent.md
|-- Search-CopilotDlpAndDspmEvidence.md
`-- Get-CopilotDlpSensitiveInfoType.md
```

Only the six documented commands are exported. Helpers are dot-sourced by the module loader and remain private to module scope.

## API documentation

- [Microsoft 365 Copilot Chat API overview](https://learn.microsoft.com/microsoft-365-copilot/extensibility/api/ai-services/chat/overview)
- [Audit log activities (Microsoft Purview)](https://learn.microsoft.com/purview/audit-log-activities)
- [Search-UnifiedAuditLog](https://learn.microsoft.com/powershell/module/exchange/search-unifiedauditlog)
- [List security alerts v2](https://learn.microsoft.com/graph/api/security-list-alerts_v2)
- [Export-ActivityExplorerData](https://learn.microsoft.com/powershell/module/exchangepowershell/export-activityexplorerdata)
- [Sensitive information type entity definitions](https://learn.microsoft.com/purview/sit-sensitive-information-type-entity-definitions)

## License

MIT
