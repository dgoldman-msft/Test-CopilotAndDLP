---
external help file: Test-CopilotAndDLP-help.xml
Module Name: Test-CopilotAndDLP
online version:
schema: 2.0.0
---

# Search-CopilotDlpDspmEvent

## SYNOPSIS
Searches DSPM Activity Explorer for a Copilot DLP conversation.

## SYNTAX

```
Search-CopilotDlpDspmEvent [[-ConversationId] <String>] [[-UserPrincipalName] <String>]
 [[-ResultPath] <String>] [[-StartDateUtc] <DateTime>] [[-EndDateUtc] <DateTime>] [[-PaddingMinutes] <Int32>]
 [[-TenantId] <String>] [[-ConversationIdLookbackDays] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Queries Microsoft Purview Activity Explorer through
Export-ActivityExplorerData and returns Copilot and DLP events whose JSON
payload contains the exact ConversationId.
The command supports one
conversation, pipeline input, or every record in a Test-CopilotAndDLP JSONL
result file.

Activity Explorer can lag unified audit by 60 to 90 minutes or longer and
reports only the last 30 days.
This command requires Security & Compliance
PowerShell permissions for Activity Explorer.
It reuses an existing session
when Export-ActivityExplorerData is available in the current process.
When no
reusable session exists, it calls Connect-IPPSSession.
Console and PowerShell
streams are isolated during connection so affected ExchangeOnlineManagement
versions can't expose an internal MSAL call stack to the end user.
When a row
has a nested CopilotEventData.ConversationId, that exact value is used for
matching; otherwise the command falls back to a substring search of the
serialized row.

Output fields verified against a real "Copilot Interaction" row for the
PurviewForAI data platform include RecordIdentity, ActivityId, AppLocation,
AppHost, DataPlatform, ClientIP, AppIdentity, AppIdentityCategory,
AppIdentityGroup, UserType, LicenseType, ThreadId, DLPEvaluationDeferred,
MemoryUpdated, Messages (message IDs and isPrompt/JailbreakDetected flags
only, not prompt or response text), AISystemPlugin (Name/Id pairs),
HasWebsearchQuery, AreFilesReferenced, AreSensitiveFilesReferenced, and
SensitivityLabelIdsReferenced.
Activity Explorer does not expose raw
prompt or response text through this API.
Field availability can vary by
tenant, activity type, and Purview portal version; every field is returned
as null when absent rather than causing an error.

## EXAMPLES

### EXAMPLE 1
```
Search-CopilotDlpDspmEvent `
    -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
    -StartDateUtc '2026-09-02T15:00:00Z'
```

Returns Activity Explorer records containing the exact conversation ID.

### EXAMPLE 2
```
Search-CopilotDlpDspmEvent -ResultPath './copilot-dlp-results.jsonl'
```

Searches every saved validation record using one compliance connection.

### EXAMPLE 3
```
Search-CopilotDlpDspmEvent
```

Called with no arguments in the directory containing copilot-dlp-results.jsonl,
searches every record in that file automatically.

### EXAMPLE 4
```
Search-CopilotDlpDspmEvent -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5'
```

A ConversationId copied from the Purview alerts portal's Correlation ID field,
with no -StartDateUtc supplied.
The command looks it up in
copilot-dlp-results.jsonl first; if it isn't there, it searches the last 7
days instead of the usual two-hour default.

## PARAMETERS

### -ConversationId
Copilot conversation ID to match exactly in DSPM event data.

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
Position: 8
Default value: 7
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndDateUtc
End of the DSPM search window.
Defaults to the current UTC time.
Values in the future are clamped to the current time because Activity Explorer rejects
future dates.

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
Minutes added around the validation time.
Defaults to 60.

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
Every record is searched.
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

### -StartDateUtc
Start of the DSPM search window.
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
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserPrincipalName
Optional test user used to further constrain matching DSPM records.

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
