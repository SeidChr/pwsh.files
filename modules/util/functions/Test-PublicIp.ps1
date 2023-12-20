param(
    [switch] $Repeat,
    [switch] $PassThrou,
    [int] $DelaySeconds = 1
)

$stdArgs = @{
    ea = 'SilentlyContinue'
}

function execute {
    $result = @{
        Time = Get-Date
        Latency = (Test-Connection google.de -Ping -Count 1 @stdArgs).Latency
        PublicIp = Invoke-RestMethod "https://api64.ipify.org" @stdArgs
    }

    if ($PassThrou) {
        $result
    } else {
        Write-Host ("Time={0:HH:mm:ss.fff} PublicIp={1} Latency={2}" -f $result.Time, $result.PublicIp, $result.Latency)
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

$nextRun = [datetime]::Now

if ($Repeat) {
    while ($true) {
        $nextRun = $nextRun.AddSeconds($DelaySeconds)
        execute
        $nextRun = waitTill $nextRun
    }
} else {
    execute
}
