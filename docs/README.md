---
Module Name: Test-CopilotAndDLP
Module Guid: d6c38774-a617-4b45-a802-d3886db53f6b
Download Help Link: NA
Help Version: 1.0
Locale: en-US
---

# Test-CopilotAndDLP Module

## Description

Submits approved synthetic sensitive-data prompts to Microsoft 365 Copilot Chat
and correlates the resulting conversation with Microsoft Purview unified audit
records and Microsoft Graph DLP alert summaries.

## Typical workflow

```powershell
Import-Module ./1.0/Test-CopilotAndDLP.psd1 -Force

$result = Test-CopilotAndDLP `
    -TestSensitiveText '<approved synthetic value>' `
    -SensitiveInfoTypeLabel 'U.S. social security number (SSN)' `
    -Confirm:$false

# Exact ConversationId match in the unified audit log
$auditEvent = $result | Search-CopilotDlpAuditEvent -UseDeviceCode

# Corresponding Microsoft Graph DLP alert by user and activity window
$alert = $result | Search-CopilotDlpAlert

# Or retrieve unified audit, DSPM, and the DLP alert together
$evidence = $result | Search-CopilotDlpAndDspmEvidence
```

To recheck all saved submissions after audit ingestion completes:

```powershell
Search-CopilotDlpAuditEvent `
    -ResultPath './copilot-dlp-results.jsonl' `
    -UseDeviceCode
```

The unified audit command performs an exact match against
`CopilotEventData.ConversationId`. The Graph alert API doesn't expose the
conversation ID, so alert summaries are correlated by test user and overlapping
activity time. Multiple interactions can be grouped into one DLP alert.

## Test-CopilotAndDLP Cmdlets

### [Test-CopilotAndDLP](Test-CopilotAndDLP.md)

Submits a synthetic sensitive-data prompt to Microsoft 365 Copilot Chat.

### [Search-CopilotDlpAuditEvent](Search-CopilotDlpAuditEvent.md)

Searches one conversation, pipeline input, or every record in a JSONL result
file and returns exact unified-audit conversation matches.

### [Search-CopilotDlpAlert](Search-CopilotDlpAlert.md)

Retrieves Microsoft Graph DLP alert summaries corresponding to validation runs
by user evidence and activity window.

### [Get-CopilotDlpSensitiveInfoType](Get-CopilotDlpSensitiveInfoType.md)

Lists Microsoft Purview built-in sensitive information types that can be targeted with Test-CopilotAndDLP.

### [Search-CopilotDlpDspmEvent](Search-CopilotDlpDspmEvent.md)

Returns exact conversation matches from DSPM Activity Explorer.

### [Search-CopilotDlpAndDspmEvidence](Search-CopilotDlpAndDspmEvidence.md)

Returns unified audit, DSPM Activity Explorer, and Graph DLP alert evidence together.
