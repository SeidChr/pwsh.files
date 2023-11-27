[CmdletBinding()]
param(
    [switch] $Auth
)

if ($Auth) {
    @{
        SteamId = Read-Host -Prompt "Steam-Id" -AsSecureString | ConvertFrom-SecureString
        ApiKey  = Read-Host -Prompt "ApiKey" -AsSecureString | ConvertFrom-SecureString
    } | ConvertTo-Json > "~/SteamApi.json"

    Write-Host "Data saved to SteamApi.json in your user-folder"
}

$secureAuth = Get-Content -Raw -Path "~/SteamApi.json" | ConvertFrom-Json

$SteamId = $secureAuth.SteamId | ConvertTo-SecureString | ConvertFrom-SecureString -AsPlainText
$ApiKey  = $secureAuth.ApiKey  | ConvertTo-SecureString | ConvertFrom-SecureString -AsPlainText


if (!$ApiKey -or !$SteamId) {
    throw "Provide API-Key and SteamId using the -Auth parameter (interactive). Register an API Key: https://steamcommunity.com/dev/apikey"
}

function ConfirmLink {
    param($Link, $Game)
    Write-Host "Playing '$Game': $Link"
    if ($Join) {
        $programFiles = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)
        Start-Process "$programFiles\Steam\steam.exe" $Link
    } else {
        $Link | Set-Clipboard
        Write-Host "Link copied to clipboard!"
    }
}

# https://www.unknowncheats.me/forum/counterstrike-global-offensive/210094-build-lobbylink.html
Invoke-RestMethod "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$ApiKey&steamids=$SteamId" 
| ForEach-Object response
| ForEach-Object players
| ForEach-Object {
    Write-Debug $_
    if ($_.lobbysteamid) {
        ConfirmLink -Link:"steam://joinlobby/$($_.gameid)/$($_.lobbysteamid)/$SteamId" -Game:$_.gameextrainfo
    } elseif ($_.gameserverip) {
        ConfirmLink -Link:"steam://connect/$($_.gameserverip)" -Game:$_.gameextrainfo
    } elseif ($_.gameextrainfo) {
        Write-Host "Playing '$Game': No Lobby Data (in a foreign Lobby)"
    } else {
        Write-Host "No game data. User not playing?"
    }
}
