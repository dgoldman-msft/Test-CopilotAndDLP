---
external help file: Test-CopilotAndDLP-help.xml
Module Name: Test-CopilotAndDLP
online version:
schema: 2.0.0
---

# Search-CopilotDlpAuditEvent

## SYNOPSIS
Searches the Microsoft Purview unified audit log for Copilot interaction
records that may correspond to a Test-CopilotAndDLP run.

## SYNTAX

```
Search-CopilotDlpAuditEvent [[-UserPrincipalName] <String>] [[-ConversationId] <String>]
 [[-ResultPath] <String>] [[-StartDateUtc] <DateTime>] [[-EndDateUtc] <DateTime>] [[-PaddingMinutes] <Int32>]
 [[-TenantId] <String>] [-UseDeviceCode] [[-ResultSize] <Int32>] [-PollForMatch]
 [[-PollIntervalSeconds] <Int32>] [[-PollTimeoutMinutes] <Int32>] [[-ConversationIdLookbackDays] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Queries the unified audit log (RecordType CopilotInteraction) for a
conversation ID, user, and time window, so you can correlate a
Test-CopilotAndDLP run with the Microsoft Purview audit trail.
A returned record confirms that a Copilot
interaction was audited for that user in that window; it does not by
itself confirm which DLP policy (if any) matched the prompt.

Audit log ingestion can lag by 30 minutes or more after the interaction
occurred.
If no records are found, wait and run the search again.

For the actual sensitive-information-type matches and prompt text
detected for an interaction, use the Activity explorer in Data Security
Posture Management (DSPM) for AI, or Content Search, in the Microsoft
Purview portal.
For a DLP policy match that is configured to generate an
alert, check Alerts in the Microsoft Purview portal or query the
Microsoft Graph Security API (alerts_v2).

This command requires the ExchangeOnlineManagement module and a role
with unified audit log read permissions (for example, View-Only Audit
Logs or Audit Logs) in Microsoft Purview or Exchange Online.

If the current PowerShell process already has an active Exchange Online
connection with a valid token, the command reuses it and doesn't prompt
for authentication.
Connections are process-scoped; a connection in a
different terminal or PowerShell process can't be reused.

## EXAMPLES

### EXAMPLE 1
```
Search-CopilotDlpAuditEvent -UserPrincipalName 'dlp-tester@contoso.example' `
    -StartDateUtc (Get-Date).AddHours(-2)
```

Searches the last two hours of CopilotInteraction audit records for the
specified test account.

### EXAMPLE 2
```
$result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
$result | Search-CopilotDlpAuditEvent
```

Pipes a Test-CopilotAndDLP result directly into the audit search using its
ConversationId, TestUser, and StartedAtUtc properties.
Only an audit record
containing that exact conversation ID is returned.

### EXAMPLE 3
```
Search-CopilotDlpAuditEvent `
    -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
    -StartDateUtc (Get-Date).AddHours(-2)
```

Searches for a CopilotInteraction record with an exact conversation ID.

### EXAMPLE 4
```
Search-CopilotDlpAuditEvent `
    -ResultPath './copilot-dlp-results.jsonl' `
    -UseDeviceCode
```

Reads every validation result in the JSONL file and returns the corresponding
unified audit information for each ConversationId.

### EXAMPLE 5
```
$result = Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false
$result | Search-CopilotDlpAuditEvent -PollForMatch -PollTimeoutMinutes 45
```

Polls on a backoff schedule for up to 45 minutes until the matching
CopilotInteraction audit record appears, instead of a single search attempt.

### EXAMPLE 6
```
Search-CopilotDlpAuditEvent
```

Called with no arguments in the directory containing copilot-dlp-results.jsonl,
searches every record in that file automatically.

### EXAMPLE 7
```
Search-CopilotDlpAuditEvent -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5'
```

A ConversationId copied from the Purview alerts portal's Correlation ID field,
with no -StartDateUtc supplied.
The command looks it up in
copilot-dlp-results.jsonl first; if it isn't there, it searches the last 7
days instead of the usual one-hour default.

## PARAMETERS

### -ConversationId
The Copilot conversation ID to match exactly in the JSON audit payload.
Accepts the ConversationId property from a Test-CopilotAndDLP result object
by pipeline binding.
Either ConversationId or UserPrincipalName must be supplied.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ConversationIdLookbackDays
When -ConversationId is supplied directly with no -StartDateUtc, and that
conversation isn't in the default copilot-dlp-results.jsonl file, how many
days to look back instead of the usual one-hour default.
Applies to
ConversationId values obtained from the Purview alerts portal rather than a
saved run.
Defaults to 7.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: 7
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndDateUtc
End of the search window in UTC.
Defaults to the current time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: (Get-Date).ToUniversalTime()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaddingMinutes
Minutes to subtract from StartDateUtc and add to EndDateUtc, to allow for
clock skew and audit log processing delay.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### -PollForMatch
Retries the search on a backoff schedule until a matching audit record
appears or -PollTimeoutMinutes elapses, instead of a single search attempt.
Useful because audit ingestion can lag by 30 minutes or more.
Can't be
combined with -ResultPath.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PollIntervalSeconds
Delay before the first retry when -PollForMatch is set.
Doubles after each
unsuccessful attempt, up to 5 minutes.
Defaults to 60.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### -PollTimeoutMinutes
Maximum time to keep retrying when -PollForMatch is set before giving up
and writing a warning.
Use 0 to make a single attempt.
Defaults to 30.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResultPath
Path to a Test-CopilotAndDLP JSONL result file.
The command reads every
validation record, searches each ConversationId, and returns the submission
metadata together with the corresponding complete unified audit record.
When
called directly (not from the pipeline) with no -ConversationId,
-UserPrincipalName, or -ResultPath, the command looks for
copilot-dlp-results.jsonl in the current directory and uses it automatically;
if that file doesn't exist, it throws asking for -ConversationId.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResultSize
Maximum number of unified audit log records to return.
Defaults to 100.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDateUtc
Start of the search window in UTC.
Accepts the StartedAtUtc property
from a Test-CopilotAndDLP result object by pipeline binding.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: StartedAtUtc

Required: False
Position: 4
Default value: (Get-Date).ToUniversalTime().AddHours(-1)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantId
Microsoft Entra tenant ID or verified tenant domain for the Exchange
Online connection.
When omitted, interactive sign-in determines the
tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDeviceCode
Uses Exchange Online device-code authentication.
Without this switch, the
command uses interactive authentication and passes UserPrincipalName as the
account hint.
UserPrincipalName identifies the account but isn't a credential
or token, so authentication can still be required when no connection exists.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserPrincipalName
The signed-in test account used to narrow the search.
Accepts the TestUser
property from a Test-CopilotAndDLP result object by pipeline binding.
Either
UserPrincipalName or ConversationId must be supplied.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TestUser

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
