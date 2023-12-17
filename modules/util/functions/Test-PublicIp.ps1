param(
    [switch] $Repeat
)

function execute {
    $ping = Test-Connection google.de -Ping -Count 1
    $ip = Invoke-RestMethod "https://api64.ipify.org"
    Write-Host "Time=$(Get-Date -Format "HH:mm:ss.fffffff") PublicIp=$ip Latency=$($ping.Latency)"
}

function wait {
    Start-Sleep -Seconds 1
}

if ($Repeat) {
    while ($true) {
        execute
        wait
    }
} else {
    execute
}
