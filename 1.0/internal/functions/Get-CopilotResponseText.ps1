function Get-CopilotResponseText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [object] $Response
    )

    if ($null -eq $Response) {
        return $null
    }

    $messages = if ($Response -is [Collections.IDictionary]) {
        $Response['messages']
    }
    elseif ($Response.PSObject.Properties.Name -contains 'messages') {
        $Response.messages
    }

    if ($null -eq $messages -or @($messages).Count -eq 0) {
        return $null
    }

    $lastMessage = @($messages)[-1]
    if ($lastMessage -is [Collections.IDictionary]) {
        return $lastMessage['text']
    }
    if ($lastMessage.PSObject.Properties.Name -contains 'text') {
        return $lastMessage.text
    }

    return $null
}
