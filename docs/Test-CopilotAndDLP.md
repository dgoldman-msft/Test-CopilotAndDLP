---
external help file: Test-CopilotAndDLP-help.xml
Module Name: Test-CopilotAndDLP
online version:
schema: 2.0.0
---

# Test-CopilotAndDLP

## SYNOPSIS
Submits a synthetic sensitive-data prompt to Microsoft 365 Copilot Chat.

## SYNTAX

```
Test-CopilotAndDLP [-TestSensitiveText] <String[]> [[-SensitiveInfoTypeLabel] <String>] [[-TenantId] <String>]
 [[-TimeZone] <String>] [-EnableWebSearch] [-UseDeviceCode] [[-ResultPath] <String>] [[-LogPath] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a Microsoft 365 Copilot conversation and sends a prompt through the
preview Microsoft Graph Copilot Chat API.
Correlate the returned run metadata
with the expected Microsoft Purview DLP alert or audit event.
A successful API
response proves prompt submission only; it does not prove that a DLP rule matched.

This API requires delegated authentication, a Microsoft 365 Copilot add-on
license, and all requested delegated scopes.
Use only synthetic test data
approved by your organization.

## EXAMPLES

### EXAMPLE 1
```
Test-CopilotAndDLP -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -WhatIf
```

Previews the test without authentication or network calls.

### EXAMPLE 2
```
Test-CopilotAndDLP -TenantId 'contoso.onmicrosoft.com' `
    -TestSensitiveText 'REPLACE-WITH-APPROVED-VALUE' -Confirm:$false -Verbose
```

Authenticates, submits the prompt, and records non-sensitive correlation data.

### EXAMPLE 3
```
Test-CopilotAndDLP -TestSensitiveText '4111111111111111' `
    -SensitiveInfoTypeLabel 'Credit card number' -Confirm:$false
```

Tests the Credit card number sensitive information type using a
well-known, publicly documented test card number instead of an SSN.

### EXAMPLE 4
```
'REPLACE-WITH-APPROVED-VALUE-1', 'REPLACE-WITH-APPROVED-VALUE-2' |
    Test-CopilotAndDLP -Confirm:$false
```

Runs a two-scenario regression batch, signing in to Microsoft Graph once and
submitting one prompt per piped value.

## PARAMETERS

### -EnableWebSearch
Enables web-search grounding.
It is disabled by default to isolate prompt DLP.

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

### -LogPath
Timestamped text log recording progress for this run.
Sensitive text and
Copilot response text are never written to this file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: (Join-Path (Get-Location).Path 'copilot-dlp.log')
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
JSON Lines correlation log.
Sensitive text and Copilot response text are never
written to this file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: (Join-Path (Get-Location).Path 'copilot-dlp-results.jsonl')
Accept pipeline input: False
Accept wildcard characters: False
```

### -SensitiveInfoTypeLabel
Corroborative keyword phrase paired with -TestSensitiveText in the prompt, to
raise match confidence for the targeted sensitive information type.
Must be
an exact name from the bundled Microsoft Purview sensitive information type
catalog (tab-completable); use Get-CopilotDlpSensitiveInfoType to browse all
supported names and their Microsoft Learn documentation links.
Defaults to
'U.S.
social security number (SSN)'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: U.S. social security number (SSN)
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantId
Microsoft Entra tenant ID or verified tenant domain.
When omitted, interactive
sign-in determines the tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestSensitiveText
One or more synthetic text values expected to match the sensitive information
type under test.
The command adds the corroborative phrase from
-SensitiveInfoTypeLabel next to each value.
Accepts an array, a comma-separated
list, or pipeline input; the command submits one Copilot conversation per value
and returns one result object per value, reusing a single Microsoft Graph
sign-in across the batch.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TimeZone
IANA time-zone name sent as the Copilot location hint.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: America/New_York
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDeviceCode
Uses device-code authentication instead of Windows Web Account Manager.

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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
