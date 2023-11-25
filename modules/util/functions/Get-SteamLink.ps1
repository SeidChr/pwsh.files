param(
    [string]$ApiKey, 
    [string]$VanityUrl, 
    [string]$SteamId
)

if (!$ApiKey -or (!$SteamId -and !$VanityUrl)) {
    throw "Provide API-Key and SteamId or VanityUrl. Register an API Key: https://steamcommunity.com/dev/apikey"
}

if (!$SteamId) {
    $SteamId = Invoke-RestMethod "http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=$ApiKey&vanityurl=$VanityUrl" 
    | ForEach-Object response 
    | ForEach-Object steamid
}

Invoke-RestMethod "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$ApiKey&steamids=$SteamId" 
| ForEach-Object response 
| ForEach-Object players 
| ForEach-Object { 
    if ($_.lobbysteamid) {
        $link = "steam://joinlobby/$($_.gameid)/$($_.lobbysteamid)/$SteamId"
        Write-Host $link
        $link | Set-Clipboard 
        Write-Host "Link copied to clipboard!" 
    } else {
        Write-Host "No game data. User not playing?"
    }
} 
