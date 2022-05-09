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

$lastState = [bool[]]::new($Target.Count)

do {
    Test-Connection -TargetName $Target -TimeoutSeconds $TimeoutSeconds -Count 1 | ForEach-Object {
        $index = [array]::indexof($Target, $_.Destination)
        $pingSuccess = $_.Status -eq 0
        if ($lastState[$index] -ne $pingSuccess) {
            Write-Host "$($pingSuccess ? "Found" : "Lost") Device $($_.Destination) at $(Get-Date)"
            $lastState[$index] = $pingSuccess
        }
    }

    Start-Sleep -Seconds $DelaySeconds
} while ($true)