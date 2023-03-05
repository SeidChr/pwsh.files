# uses VT and utils module from the modules directory

function Register-Gpt {
    Unlock
    $secureApiKey = Read-Host "Enter the OpenAi Api Key" -AsSecureString
    Set-Secret -Name 'OpenAiApiKey' -SecureStringSecret $secureApiKey
}

function Connect-Gpt {
    Unlock

    $global:OpenAiApiKey = Get-Secret -Name 'OpenAiApiKey' -ErrorAction SilentlyContinue
    if (-not $global:OpenAiApiKey) {
        Write-Host "Unable to connect to Gpt. Use Register-Gpt and enter an api-key."
        return $false
    }

    return $true
}

function Initialize-GptMessages {
    [OutputType([System.Collections.ArrayList])]
    $messages = [System.Collections.ArrayList]::new()
    $null = $messages.Add(@{ "role" = "system"; "content" = "you keep your answers short and minimal and come to the point quickly" })
    $null = $messages.Add(@{ "role" = "system"; "content" = "you will never specify that you are an AI language model." })
    Write-Output -NoEnumerate $messages
}

function Test-GptAuth {
    if (-not ($global:OpenAiApiKey)) {
        return Connect-Gpt
    }

    return $true;
}

function Complete-GptMessages {
    param([System.Collections.ArrayList] $Messages, $Model = "gpt-3.5-turbo")

    $conversation = @{ "model" = "gpt-3.5-turbo"; "messages" = $Messages }
    $splat = @{
        Method      = "Post"
        Body        = $conversation | ConvertTo-Json -Depth 10 -Compress
        Uri         = "https://api.openai.com/v1/chat/completions"
        ContentType = "application/json"
    }

    $response = Invoke-RestMethod @splat -Headers @{ Authorization = "Bearer $($global:OpenAiApiKey | ConvertFrom-SecureString -AsPlainText)" }
    $responseMessage = $response.choices[0].message
    $null = $Messages.Add($responseMessage)

    $responseMessage.Content
}

filter Format-GptConsoleMessage {
    $_.Replace('\n', [System.Environment]::NewLine).Trim()
}

function Hey-Gpt {
    param([string] $Message, [switch]$Reset)

    if (-not (Test-GptAuth)) { return }

    if ($Reset -or (-not $global:OpenAiChatMessages)) {
        $global:OpenAiChatMessages = Initialize-GptMessages
    }

    $null = $global:OpenAiChatMessages.Add(@{ "role" = "user"; "content" = $message })

    Complete-GptMessages -Messages $global:OpenAiChatMessages | Format-GptConsoleMessage
}

function Start-GptConversation {
    param($HumanName = "Hooman", $AiName = "Gpt")

    if (-not (Test-GptAuth)) { return }

    $messages = Initialize-GptMessages

    do {
        $null = $messages.Add(@{ "role" = "user"; "content" = (Read-Host ($HumanName | Add-Color "0f0")) })
        Write-Host "$(Get-VtTextColor "f00")Gpt$(Get-VtClear):"
        Write-Host (Complete-GptMessages -Messages $messages | Format-GptConsoleMessage)
    } while ($true)
}
