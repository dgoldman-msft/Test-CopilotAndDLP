function Resolve-CopilotDlpConversationWindow {
    <#
    .SYNOPSIS
    Resolves a search-window start time and test user for a ConversationId
    supplied without an explicit -StartDateUtc.

    .DESCRIPTION
    Looks up ConversationId in the default copilot-dlp-results.jsonl file in the
    current directory. If a matching record is found, its StartedAtUtc and
    TestUser are reused so the caller can search an exact, narrow window. If no
    default file exists or the conversation isn't in it (for example, a
    ConversationId pasted from the Purview alerts portal), a widened lookback
    window is returned instead, since no activity time is otherwise known.

    .PARAMETER ConversationId
    Copilot conversation ID to look up.

    .PARAMETER UserPrincipalName
    Test user already supplied by the caller, if any. Only overridden when empty.

    .PARAMETER LookbackDays
    Number of days to look back when no saved run is found for ConversationId.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string] $ConversationId,

        [string] $UserPrincipalName,

        [ValidateRange(1, 90)]
        [int] $LookbackDays = 7
    )

    $defaultResultPath = Join-Path (Get-Location).Path 'copilot-dlp-results.jsonl'
    if (Test-Path -LiteralPath $defaultResultPath -PathType Leaf) {
        $matchingRecord = Get-Content -LiteralPath $defaultResultPath -ErrorAction SilentlyContinue |
            ConvertFrom-Json -ErrorAction SilentlyContinue |
            Where-Object { [string] $_.ConversationId -eq $ConversationId } |
            Select-Object -First 1

        if ($matchingRecord) {
            return [pscustomobject]@{
                StartDateUtc      = [datetime] $matchingRecord.StartedAtUtc
                UserPrincipalName = if ($UserPrincipalName) { $UserPrincipalName } else { [string] $matchingRecord.TestUser }
                Source            = "the saved run in '$defaultResultPath'"
            }
        }
    }

    [pscustomobject]@{
        StartDateUtc      = (Get-Date).ToUniversalTime().AddDays(-1 * $LookbackDays)
        UserPrincipalName = $UserPrincipalName
        Source            = "a widened $LookbackDays-day lookback (no saved run or activity time was found for this ConversationId)"
    }
}
