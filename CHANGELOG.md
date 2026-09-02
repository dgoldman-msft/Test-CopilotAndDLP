# Changelog

All notable changes to this project are documented here.

## Unreleased

- Added `Get-CopilotDlpSensitiveInfoType`, a bundled catalog of 300+ Microsoft Purview built-in sensitive information type definitions, so any SIT can be discovered and referenced by name for use with `-SensitiveInfoTypeLabel`.
- `-SensitiveInfoTypeLabel` on `Test-CopilotAndDLP` is now a strict `ValidateSet` enforced against the bundled catalog (325 names, case-insensitive) with tab completion; unlisted values are rejected. The default changed from `Social Security Number` to the exact catalog entry `U.S. social security number (SSN)`.
- Added `Search-CopilotDlpAuditEvent` to correlate a `Test-CopilotAndDLP` run with Microsoft Purview unified audit log `CopilotInteraction` records.
- Added `-LogPath` timestamped progress logging (console and file) to `Test-CopilotAndDLP`.
- `Test-CopilotAndDLP` now checks for and installs `Microsoft.Graph.Authentication` automatically if missing.
- Added PlatyPS-generated command help under `docs/`.

## 1.0.0 - 2026-09-02

- Added the `Test-CopilotAndDLP` PowerShell module command.
- Added delegated Microsoft Graph authentication and Copilot Chat submission.
- Added `-WhatIf`/`-Confirm`, device-code authentication, and web-search controls.
- Added non-sensitive JSONL correlation logging and Pester coverage.
