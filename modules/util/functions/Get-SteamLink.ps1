# 
param(
    [string] $ApiKey, 
    [string] $VanityUrl, 
    [string] $SteamId,
    [switch] $Join
)

if (!$ApiKey -or (!$SteamId -and !$VanityUrl)) {
    throw "Provide API-Key and SteamId or VanityUrl. Register an API Key: https://steamcommunity.com/dev/apikey"
}

if (!$SteamId) {
    # https://stackoverflow.com/questions/19247887/get-steamid-by-user-nickname
    # https://wiki.teamfortress.com/wiki/WebAPI/ResolveVanityURL
    $SteamId = Invoke-RestMethod "http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=$ApiKey&vanityurl=$VanityUrl" 
    | ForEach-Object response 
    | ForEach-Object steamid
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
| Tee-Object -Variable "response"
| ForEach-Object {
    if ($_.lobbysteamid) {
        ConfirmLink -Link:"steam://joinlobby/$($_.gameid)/$($_.lobbysteamid)/$SteamId" -Game:$_.gameextrainfo
    } elseif ($_.gameserverip) {
        ConfirmLink -Link:"steam://connect/$($_.gameserverip)" -Game:$_.gameextrainfo
    } else {
        Write-Host "No game data. User not playing?"
    }
} 
