---
external help file: Test-CopilotAndDLP-help.xml
Module Name: Test-CopilotAndDLP
online version:
schema: 2.0.0
---

# Get-CopilotDlpSensitiveInfoType

## SYNOPSIS
Lists Microsoft Purview built-in sensitive information types (SITs) that
can be targeted with Test-CopilotAndDLP.

## SYNTAX

```
Get-CopilotDlpSensitiveInfoType [[-Name] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns entries from the bundled catalog of built-in sensitive information
type entity definitions published by Microsoft Learn, so you can find the
exact name to pass as -SensitiveInfoTypeLabel on Test-CopilotAndDLP, and
the documentation page describing that type's detection pattern.

This command only helps you discover the correct name and reference link.
It does not generate synthetic test values; you must supply a value that
matches the target type's pattern yourself, approved by your organization.

## EXAMPLES

### EXAMPLE 1
```
Get-CopilotDlpSensitiveInfoType -Name '*passport*'
```

Lists every bundled sensitive information type with "passport" in its
name, along with a link to its Microsoft Learn definition page.

### EXAMPLE 2
```
Get-CopilotDlpSensitiveInfoType -Name 'Credit card number' |
    Select-Object -ExpandProperty DocUrl
```

Gets the documentation link for the Credit Card Number sensitive
information type.

## PARAMETERS

### -Name
Filter on the sensitive information type name.
Supports wildcards
(for example, '*passport*').
Defaults to '*' (all types).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: True
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
