# .Synopsis
# .Example
# Write-PingLog -DelaySeconds 5 -TimeoutSeconds 2 -Target 192.168.0.10
# Found Device 192.168.0.10 at 05/08/2022 20:28:10
# Lost Device 192.168.0.10 at 05/08/2022 20:32:53

param(
    [int]$DelaySeconds = 1,
    [int]$TimeoutSeconds = 1,
    [string[]]$Target,
    [switch] $PassThru
)

$lastState = [bool[]]::new($Target.Count)

do {
    Test-Connection -TargetName $Target -TimeoutSeconds $TimeoutSeconds -Count 1 | ForEach-Object {
        $index = [array]::indexof($Target, $_.Destination)
        $pingSuccess = $_.Status -eq 0
        if ($lastState[$index] -ne $pingSuccess) {
            $lastState[$index] = $pingSuccess
            if ($PassThru) {
                @{
                    Status    = $pingSuccess
                    Target    = "$($_.Destination)"
                    Timestamp = Get-Date
                }
            } else {
                Write-Host "$($pingSuccess ? "Found" : "Lost") Device $($_.Destination) at $(Get-Date)"
            }
        }
    }

    Start-Sleep -Seconds $DelaySeconds
} while ($true)