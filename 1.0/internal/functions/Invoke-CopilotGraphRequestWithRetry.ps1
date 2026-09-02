function Invoke-CopilotGraphRequestWithRetry {
    <#
    .SYNOPSIS
    Calls Invoke-MgGraphRequest with retry/backoff for transient 429/503 responses.

    .DESCRIPTION
    Wraps Invoke-MgGraphRequest so transient throttling (429) or service
    unavailability (503) responses are retried with exponential backoff
    instead of failing the whole Test-CopilotAndDLP run. Non-transient errors
    are re-thrown immediately on the first attempt.

    .PARAMETER Method
    HTTP method passed to Invoke-MgGraphRequest.

    .PARAMETER Uri
    Request URI passed to Invoke-MgGraphRequest.

    .PARAMETER ContentType
    Request content type passed to Invoke-MgGraphRequest.

    .PARAMETER Body
    Request body passed to Invoke-MgGraphRequest.

    .PARAMETER MaxAttempts
    Maximum number of attempts, including the first. Defaults to 5.

    .PARAMETER InitialDelaySeconds
    Delay before the first retry. Doubles after each subsequent transient
    failure, up to MaxDelaySeconds. Defaults to 2.

    .PARAMETER MaxDelaySeconds
    Upper bound for the backoff delay. Defaults to 30.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string] $Method,

        [Parameter(Mandatory)]
        [string] $Uri,

        [string] $ContentType = 'application/json',

        [string] $Body,

        [ValidateRange(1, 10)]
        [int] $MaxAttempts = 5,

        [ValidateRange(1, 60)]
        [int] $InitialDelaySeconds = 2,

        [ValidateRange(1, 300)]
        [int] $MaxDelaySeconds = 30
    )

    $attempt = 0
    $delaySeconds = $InitialDelaySeconds

    while ($true) {
        $attempt++
        try {
            $requestParameters = @{
                Method      = $Method
                Uri         = $Uri
                ContentType = $ContentType
            }
            if ($PSBoundParameters.ContainsKey('Body')) {
                $requestParameters.Body = $Body
            }
            return Invoke-MgGraphRequest @requestParameters -ErrorAction Stop
        }
        catch {
            # The Graph SDK doesn't consistently expose a structured status code across versions, so match the reported text.
            $isTransient = $_.Exception.Message -match '429|503|Too\s*Many\s*Requests|Service\s*Unavailable'
            if (-not $isTransient -or $attempt -ge $MaxAttempts) {
                throw
            }

            Write-Verbose "Transient Microsoft Graph error on attempt $attempt of $MaxAttempts. Waiting $delaySeconds second(s) before retry."
            Start-Sleep -Seconds $delaySeconds
            $delaySeconds = [Math]::Min($delaySeconds * 2, $MaxDelaySeconds)
        }
    }
}
