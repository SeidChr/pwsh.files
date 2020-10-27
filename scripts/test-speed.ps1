# https://github.com/sivel/speedtest-cli/blob/master/speedtest.py

param ([int] $packageSizeMb = 1)

# load functions
. Import-ScriptsAsFunctions ( Join-Path $PSScriptRoot "functions" )

$urls = 'www.speedtest.net/speedtest-servers-static.php',
'c.speedtest.net/speedtest-servers-static.php',
'www.speedtest.net/speedtest-servers.php',
'c.speedtest.net/speedtest-servers.php'

$ProgressPreference = 'SilentlyContinue'

$servers = $urls `
    | ForEach-Object { Invoke-WebRequest $_ } `
    | ForEach-Object { ([xml]$_.Content).Settings.Servers.Server }

$myIp = Invoke-RestMethod -Uri "http://ifconfig.me/ip"
$myIpInfo = Invoke-RestMethod -Uri "http://ip-api.com/json/$myIp"

Write-Host "My IP Info for $myIp :"
$myIpInfo | Format-Table

$nearestServers = $servers `
| ForEach-Object {
    $_ | Add-Member `
        -Name "dist" `
        -MemberType NoteProperty `
        -Value (Get-Distance $myIpInfo.lat $myIpInfo.lon $_.lat $_.lon) `
        -PassThru 
} `
| Sort-Object -Property dist -Top 5

# https://stackoverflow.com/a/58392058/1280354
$unixTime = [long]((Get-Date).Ticks / 10000000L) - 62135596800L;

$bestServer = $nearestServers | ForEach-Object {
    $server = $_
    $avgRequestTime = 1..3 | ForEach-Object {
            Measure-WebRequest -Url "$($server.url)/latency.txt?x=$unixTime.$_" -Method Get `
                | Select-Object -ExpandProperty Milliseconds
        } `
        | Measure-Object -Average `
        | Select-Object -ExpandProperty Average

    $_ | Add-Member -Name "avglatency" -MemberType NoteProperty -Value $avgRequestTime -PassThru 
} | Sort-Object -Property avglatency -Top 1

$bestServer
$mibi = 1024 * 2024
$uploadMb = $packageSizeMb
$uploadBytes = $uploadMb * $mibi

$content = (Get-HttpBytesContent (Get-RandomBytes $uploadBytes))
$url = "$($bestServer.url)?x=$unixTime.0"

$byteCount = $uploadBytes
$bitCount = $byteCount * 8
1..10 | ForEach-Object {
        Measure-WebRequest -Method Post -Url $url -Content $content
    } `
    | Measure-Object -AllStats -Property Milliseconds `
    | ForEach-Object {
        [pscustomobject] @{
            MaxMBytePs = $byteCount / ($_.Minimum / 1000) / $mibi
            MinMBytePs = $byteCount / ($_.Maximum / 1000) / $mibi
            AvgMBytePs = $byteCount / ($_.Average / 1000) / $mibi
            MaxMBitPs = $bitCount / ($_.Minimum / 1000) / $mibi
            MinMBitPs = $bitCount / ($_.Maximum / 1000) / $mibi
            AvgMBitPs = $bitCount / ($_.Average / 1000) / $mibi
        }
    }
