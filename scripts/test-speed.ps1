# https://github.com/sivel/speedtest-cli/blob/master/speedtest.py

function Distance {
    param(
        [double]$LatOrigin, 
        [double]$lonOrigin, 
        [double]$LatDestination,
        [double]$LonDestination
    )

    $radius = 6371  # km

    # https://stackoverflow.com/a/19677131/1280354
    $rad = [Math]::PI / 180
    
    $LatOrigin *= $rad
    $LatDestination *= $rad

    $LonOrigin *= $rad
    $LonDestination *= $rad

    $dlat = $LatDestination - $LatOrigin
    $dlon = $LonDestination - $lonOrigin

    $a = (
        [Math]::sin($dlat / 2) * [Math]::sin($dlat / 2) +
        [Math]::Sin($dlon / 2) * [Math]::Sin($dlon / 2) * [Math]::Cos($LatOrigin) * [Math]::Cos($LatDestination)
    )

    $c = 2 * [Math]::Atan2([Math]::sqrt($a), [Math]::sqrt(1 - $a))
    $radius * $c
}

$urls = 'www.speedtest.net/speedtest-servers-static.php',
'c.speedtest.net/speedtest-servers-static.php',
'www.speedtest.net/speedtest-servers.php',
'c.speedtest.net/speedtest-servers.php'

$servers = $urls `
| ForEach-Object { Invoke-WebRequest $_ } `
| ForEach-Object { ([xml]$_.Content).Settings.Servers.Server }

#$servers.Count
#$servers | Sort-Object -Unique -Property Id

$myIp = Invoke-RestMethod -Uri "http://ifconfig.me/ip"
# http://ip-api.com/json/111.222.333.444/
# status      : success
# country     : Germany
# countryCode : DE
# region      : HH
# regionName  : Hamburg
# city        : Hamburg
# zip         : 20099
# lat         : 53.5553
# lon         : 9.995
# timezone    : Europe/Berlin
# isp         : Vodafone Kabel Deutschland
# org         : Kabel Deutschland Customer Services
# as          : AS3209 Vodafone GmbH
# query       : 31.16.1.157
$myIpInfo = Invoke-RestMethod -Uri "http://ip-api.com/json/$myIp"
# Write-Host $myIpInfo
$nearestServers = $servers `
| ForEach-Object {
    $_ | Add-Member `
        -Name "dist" `
        -MemberType NoteProperty `
        -Value (Distance $myIpInfo.lat $myIpInfo.lon $_.lat $_.lon) `
        -PassThru 
} `
| Sort-Object -Property dist -Top 5

# dist    : 1,18958313839957
# url     : http://speedtest.studiofunk.de:8080/speedtest/upload.php
# lat     : 53.5653
# lon     : 10.0014
# name    : Hamburg
# country : Germany
# cc      : DE
# sponsor : Studio Funk GmbH & Co. KG
# id      : 2398
# host    : speedtest.studiofunk.de:8080

# https://stackoverflow.com/a/58392058/1280354
$unixTime = [long]((Get-Date).Ticks / 10000000L) - 62135596800L;

$bestServer = $nearestServers | ForEach-Object {
    $server = $_
    $avgRequestTime = 1..3 | ForEach-Object {
        Measure-Command { 
            Invoke-WebRequest "$($server.url)/latency.txt?x=$unixTime.$_"
        } | Select-Object -ExpandProperty TotalMilliseconds
    } | Measure-Object -Average | Select-Object -ExpandProperty Average
    $_ | Add-Member -Name "avglatency" -MemberType NoteProperty -Value $avgRequestTime -PassThru 
} | Sort-Object -Property avglatency -Top 1


function Get-RandomBytes {
    param([int] $Bytes)
    [byte[]](get-random -Count $Bytes -Maximum 256)
}

$bestServer

$uploadMb = 1
$uploadBytes = ($uploadMb * 1024 * 1024)

$uploadSeconds = Measure-Command {
    $data = Get-RandomBytes -Bytes $uploadBytes
    Invoke-RestMethod `
        -Method Post `
        -Uri "$($bestServer.url)?x=$unixTime.0" -Body $data
} `
| Select-Object -ExpandProperty TotalSeconds

$uploadBits = $uploadBytes * 8

Write-Host "Seconds:" $uploadSeconds
Write-Host "Bytes:" $uploadBytes
Write-Host "Bits:" $uploadBits
Write-Host "Megabytes:" $uploadMb

# all nonsens from here .. redo!
Write-Host "MBps:" ($uploadMb / $uploadSeconds)
Write-Host "Bps:" ($uploadBytes / $uploadSeconds)
Write-Host "bps:" ($uploadBits / $uploadSeconds)
Write-Host "Mbps:" (($uploadMb * 8) / $uploadSeconds)

function Measure-PostRequest {
    param(
        [string] $Url,
        [byte[]] $Bytes,
        [switch] $Block
    )

    $content = [Net.Http.ByteArrayContent]::new($bytes);
    $version = $PSVersionTable.PSEdition + "-" + $PSVersionTable.PSVersion
    $userAgent = "Mozilla/5.0 Powershell/$version Test-Speed/0.1"
    
    $client = [Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.Add("User-Agent", $userAgent);
    $stopwatch = [Diagnostics.Stopwatch]::new()
    $result = $null;

    $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, $Url)
    $request.Content = $content;

    if ($block) {
        $stopwatch.Start()
        $result = $client.SendAsync($request).GetAwaiter().GetResult()
        $stopwatch.Stop()
    } else {
        $stopwatch.Start()
        $task = $client.SendAsync($request)
        while (-not $task.AsyncWaitHandle.WaitOne(200)) { }
        $result = $task.GetAwaiter().GetResult()
        $stopwatch.Stop()
    }

    [PSCustomObject]@{
        Response = $result
        Milliseconds = $stopwatch.ElapsedMilliseconds
    }
}

# using the c# class has almost the same performance. 
# both methods wont measure values below ~30 ms for a single byte
# powershell however, w. measure-command and invoke-rest, is remarkibly
# slower with the lowest measured value being ~110 ms

# $id = get-random
# $code = (Get-Content "RequestHelper.cs" -Raw) -replace "class RequestHelper", "class RequestHelper$id"
# Add-Type -TypeDefinition $code -Language CSharp	
# $requestHelper = Invoke-Expression "[RequestHelper$id]::new()"
