param(
    [int]$Seconds
)

for ($i = $Seconds; $i -gt 0; $i--) {
    $remaining = [TimeSpan]::FromSeconds($i)

    Write-Progress -Activity "Sleeping..." `
        -Status $remaining.ToString("hh\:mm\:ss") `
        -PercentComplete (100 * ($Seconds - $i) / $Seconds)

    Start-Sleep -Seconds 1
}

Write-Progress -Activity "Sleeping..." -Completed
