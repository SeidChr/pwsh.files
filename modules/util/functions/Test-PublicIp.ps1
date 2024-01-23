param(
    [switch] $Repeat,
    [switch] $PassThrou,
    [int] $DelaySeconds = 1,
    [switch] $AlertOnMobileConnection
)

$stdArgs = @{
    ea = 'SilentlyContinue'
}

$ipIspCache = [hashtable]::new();
$lastConnectionWasMobile = $false;

function whois {
    param([string] $Ip)
    if ((-not $ipIspCache.ContainsKey($Ip)) -or (-not $ipIspCache[$Ip])) {
        $ispResult = Invoke-RestMethod "http://ip-api.com/json/$($Ip)?fields=isp,mobile" @stdArgs
        $ipIspCache[$Ip] = $ispResult
    } 
    
    $ipIspCache[$Ip]
}

function execute {
    $ip = Invoke-RestMethod "https://api64.ipify.org" @stdArgs
    $whois = whois -Ip:$ip
    $result = @{
        Time     = Get-Date
        Latency  = (Test-Connection google.de -Ping -Count 1 @stdArgs).Latency
        PublicIp = $ip
        Isp      = $whois.isp
        IsMobile = $whois.mobile
    }

    if ($PassThrou) {
        $result
    } else {
        if ($AlertOnMobileConnection) {
            $currentConnectionIsMobile = $result.IsMobile

            if ((-not $lastConnectionWasMobile) -and $currentConnectionIsMobile) {
                [console]::beep(1000, 300); [console]::beep(1000, 300)
            } elseif ($lastConnectionWasMobile -and (-not $currentConnectionIsMobile)) {
                [console]::beep(200, 300)
            }

            $lastConnectionWasMobile = $currentConnectionIsMobile
        }

        Write-Host ("Time={0:HH:mm:ss.fff} PublicIp={1} Mobile={3} Latency={2}" -f $result.Time, $result.PublicIp, $result.Latency, $result.IsMobile)
    }
    # start-sleep -Milliseconds 1200
}

function waitTill {
    param([DateTime] $Time)
    $diffMs = -(([datetime]::Now - $Time).TotalMilliseconds)
    if ($diffMs -gt 0) {
        Start-Sleep -Milliseconds $diffMs
    }
    # if the delay is too high, add overflow
    if ($diffMs -lt -1000) {
        $added = [int]((-$diffMs)/1000)
        # Write-Host ('.'*$added)
        $Time.AddSeconds($added)
    } else {
        $Time
    }
}

if ($Repeat) {
    $nextRun = [datetime]::Now
    while ($true) {
        $nextRun = $nextRun.AddSeconds($DelaySeconds)
        execute
        $nextRun = waitTill $nextRun
    }
} else {
    execute
}
