# make sure to set your own $apiKey beforehand.

function Hey-Gpt {
    param([string] $Message, [switch]$Reset)
    if ($Reset -or (-not $global:OpenAiChatMessages)) {
        $global:OpenAiChatMessages = [System.Collections.ArrayList]::new()
    }

    $null = $global:OpenAiChatMessages.Add(@{ "role" = "user"; "content" = $message })
    $conversation = @{ "model" = "gpt-3.5-turbo"; "messages" = $global:OpenAiChatMessages }
    $splat = @{
        Method      = "Post"
        Body        = $conversation | ConvertTo-Json -Depth 10 -Compress
        Uri         = "https://api.openai.com/v1/chat/completions"
        Headers     = @{ Authorization = "Bearer $apiKey" }
        ContentType = "application/json"
    }

    $response = Invoke-RestMethod @splat
    $responseMessage = $response.choices[0].message
    $null = $global:OpenAiChatMessages.Add($responseMessage)
    $responseMessage.content.Replace('\n', [System.Environment]::NewLine).Trim()
}