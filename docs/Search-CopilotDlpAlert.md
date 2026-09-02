---
external help file: Test-CopilotAndDLP-help.xml
Module Name: Test-CopilotAndDLP
online version:
schema: 2.0.0
---

# Search-CopilotDlpAlert

## SYNOPSIS
Retrieves Microsoft Graph DLP alerts corresponding to a Copilot validation run.

## SYNTAX

```
Search-CopilotDlpAlert [-ConversationId] <String> [-UserPrincipalName] <String> [[-StartDateUtc] <DateTime>]
 [[-EndDateUtc] <DateTime>] [[-PaddingMinutes] <Int32>] [[-TenantId] <String>] [-UseDeviceCode]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Queries Microsoft Graph security alerts_v2 for Microsoft Data Loss Prevention
alerts and correlates them with a Test-CopilotAndDLP result by test user and
activity time window.

The alerts_v2 response doesn't currently expose the Copilot ConversationId,
although the Purview DLP alert portal can show it on an associated event.
Consequently, ConversationId is carried into the output for traceability, but
the alert match is based on the test user and overlapping activity time.
Use
Search-CopilotDlpAuditEvent for an exact ConversationId match in the unified
audit record.

Requires the Microsoft Graph delegated permission SecurityAlert.Read.All and
a supported Microsoft Entra role such as Security Reader, Global Reader,
Security Operator, or Security Administrator.

## EXAMPLES

### EXAMPLE 1
```
$result | Search-CopilotDlpAlert
```

Retrieves DLP alerts whose user evidence and activity window correspond to a
Test-CopilotAndDLP validation result.

### EXAMPLE 2
```
Get-Content './copilot-dlp-results.jsonl' |
    ConvertFrom-Json |
    Search-CopilotDlpAlert -UseDeviceCode
```

Reads every saved validation result and correlates each one with Microsoft
Graph DLP alerts.
Multiple interactions can belong to one aggregated alert.

### EXAMPLE 3
```
Search-CopilotDlpAlert `
    -ConversationId 'cd72ca81-239b-4b78-b9e6-74b081635dc5' `
    -UserPrincipalName 'dlp-tester@contoso.example' `
    -StartDateUtc '2026-09-02T15:09:20Z'
```

Correlates one known Copilot interaction with a DLP alert by user and
overlapping activity time.
The Graph alert summary doesn't expose the
ConversationId, so this isn't an exact ID match.

## PARAMETERS

### -ConversationId
Copilot conversation ID from Test-CopilotAndDLP.
Accepts pipeline input by
property name and is included in the correlation result.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EndDateUtc
End of the alert search window.
Defaults to the current UTC time.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Get-Date).ToUniversalTime()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PaddingMinutes
Number of minutes applied around the activity time when correlating an alert.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 10
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

### -StartDateUtc
Start of the Copilot validation run.
Accepts the StartedAtUtc property from
Test-CopilotAndDLP by pipeline input.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: StartedAtUtc

Required: False
Position: 3
Default value: (Get-Date).ToUniversalTime().AddHours(-1)
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
Uses device-code authentication instead of Windows Web Account Manager.
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
Test account used for the Copilot interaction.
Accepts the TestUser property
from Test-CopilotAndDLP by pipeline input.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TestUser

Required: True
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
