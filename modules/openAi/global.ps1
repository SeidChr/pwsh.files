function Connect-Gpt {
    param(
        [Parameter(Mandatory)]
        [string] $SecretName, 
        [string] $SecretVault
    ) 
    
    $splat = @{
        Name = $SecretName
    }

    if ($SecretVault) {
        $splat['Vault'] = $SecretVault
    }

    $global:OpenAiApiKey = Get-Secret @splat
}

function Hey-Gpt {
    param([string] $Message, [switch]$Reset)

    if (-not ($global:OpenAiApiKey)) {
        Write-Host "Please authenticate using Connect-Gpt"
    }

    if ($Reset -or (-not $global:OpenAiChatMessages)) {
        $global:OpenAiChatMessages = [System.Collections.ArrayList]::new()
    }

    $null = $global:OpenAiChatMessages.Add(@{ "role" = "user"; "content" = $message })
    $conversation = @{ "model" = "gpt-3.5-turbo"; "messages" = $global:OpenAiChatMessages }
    $splat = @{
        Method      = "Post"
        Body        = $conversation | ConvertTo-Json -Depth 10 -Compress
        Uri         = "https://api.openai.com/v1/chat/completions"
        ContentType = "application/json"
    }

    $response = Invoke-RestMethod @splat -Headers @{ Authorization = "Bearer $($global:OpenAiApiKey | ConvertFrom-SecureString -AsPlainText)" }
    $responseMessage = $response.choices[0].message
    $null = $global:OpenAiChatMessages.Add($responseMessage)
    $responseMessage.content.Replace('\n', [System.Environment]::NewLine).Trim()
}