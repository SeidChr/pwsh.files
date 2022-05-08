# .Synopsis
# .Example
# Write-PingProgress -DelaySeconds 5 -TimeoutSeconds 2 -Target 192.168.0.10, 192.168.0.11
# Ping 192.168.0.10 [Success: 557ms (28 % of 2000ms)                                                                    ]
# Ping 192.168.0.11 [Success: 277ms (14 % of 2000ms)                                                                    ]

param(
    [int]$DelaySeconds = 1,
    [int]$TimeoutSeconds = 10,
    [string[]]$Target
)

do {
    Test-Connection -TargetName $Target -TimeoutSeconds $TimeoutSeconds -Count 1 | ForEach-Object {
        $TimeoutMilliseconds = $TimeoutSeconds * 1000
        $PercentComplete = [int]($_.Latency / ( $TimeoutMilliseconds / 100 ))
        if (($_.Status -eq 0) -and ($PercentComplete -eq 0)) {
            $PercentComplete = 1
        }

        Write-Progress -Id ([array]::indexof($Target, $_.Destination)) -Activity "Ping $($_.Destination)" -Status "$($_.Status): $($_.Latency)ms ($PercentComplete% of $($TimeoutMilliseconds)ms)" -PercentComplete $PercentComplete
    }
    Start-Sleep -Seconds $DelaySeconds
} while ($true)