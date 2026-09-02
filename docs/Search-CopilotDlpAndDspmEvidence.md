---
external help file: Test-CopilotAndDLP-help.xml
Module Name: Test-CopilotAndDLP
online version:
schema: 2.0.0
---

# Search-CopilotDlpAndDspmEvidence

## SYNOPSIS
Retrieves unified audit, DSPM, and DLP alert evidence for Copilot tests.

## SYNTAX

```
Search-CopilotDlpAndDspmEvidence [[-ConversationId] <String>] [[-UserPrincipalName] <String>]
 [[-ResultPath] <String>] [[-StartDateUtc] <DateTime>] [[-EndDateUtc] <DateTime>] [[-TenantId] <String>]
 [-SkipDlpAlert] [-UseDeviceCode] [[-ConversationIdLookbackDays] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Runs all correlation paths for one Copilot ConversationId, pipeline input,
or every record in a Test-CopilotAndDLP JSONL result file.
Each output object
contains exact ConversationId matches from the unified audit log and DSPM
Activity Explorer, plus the corresponding Microsoft Graph DLP alert summary.

Each source is queried independently.
If one source fails, results from the
other sources are retained and the source-specific error is returned in
UnifiedAuditError, DspmError, or DlpAlertError.

Exchange Online (unified audit) and Security & Compliance PowerShell (DSPM)
connections are reused automatically for every record processed in this call,
and for later calls in the same PowerShell process, as long as the existing
connection's token is still active.
Microsoft Graph DLP-alert correlation for
every record runs through a single isolated child process per call, so only
one Graph sign-in is needed regardless of how many records are in ResultPath.

## EXAMPLES

### EXAMPLE 1
```
Search-CopilotDlpAndDspmEvidence `
    -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
    -UserPrincipalName 'dlp-tester@contoso.example' `
    -StartDateUtc '2026-09-02T15:00:00Z'
```

Returns all available evidence for one conversation.

### EXAMPLE 2
```
Search-CopilotDlpAndDspmEvidence -ResultPath './copilot-dlp-results.jsonl'
```

Returns all available evidence for every saved validation record.

### EXAMPLE 3
```
Search-CopilotDlpAndDspmEvidence
```

Called with no arguments in the directory containing copilot-dlp-results.jsonl,
returns evidence for every record in that file automatically.

### EXAMPLE 4
```
Search-CopilotDlpAndDspmEvidence -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5'
```

A ConversationId copied from the Purview alerts portal's Correlation ID field,
with no -StartDateUtc supplied.
The command looks it up in
copilot-dlp-results.jsonl first; if it isn't there, it searches the last 7
days instead of the usual two-hour default.

## PARAMETERS

### -ConversationId
Copilot conversation ID to investigate.
When the user and start time aren't
supplied, the command derives them from the exact unified-audit or DSPM
conversation match before searching for a corresponding DLP alert.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ConversationIdLookbackDays
When -ConversationId is supplied directly with no -StartDateUtc, and that
conversation isn't in the default copilot-dlp-results.jsonl file, how many
days to look back instead of the usual two-hour default.
Applies to
ConversationId values obtained from the Purview alerts portal rather than a
saved run.
Defaults to 7.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 7
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndDateUtc
End of the correlation search window.

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
Test-CopilotAndDLP JSONL file containing all validation records to inspect.
When called directly (not from the pipeline) with no -ConversationId,
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

### -SkipDlpAlert
Omits Microsoft Graph alerts_v2 correlation when only unified audit and DSPM
evidence are required.

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

### -StartDateUtc
Validation start time.
Accepts StartedAtUtc by property name.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: StartedAtUtc

Required: False
Position: 4
Default value: (Get-Date).ToUniversalTime().AddHours(-2)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantId
Microsoft Entra tenant ID or verified tenant domain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDeviceCode
Uses device-code authentication for unified-audit and Microsoft Graph alert
connections.
Without this switch, interactive authentication is used.

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
Test user.
Accepts TestUser by property name.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TestUser

Required: False
Position: 2
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
