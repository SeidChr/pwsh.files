param (
    [string[]] $Url,
    [int] $Sleep = 5,
    [Alias("AlarmThresholdMs")]
    [Alias("Threshold")]
    [int] $ThresholdMs = 500,
    [switch] $Alarm,
    [int] $AlarmFrequency = 2000,
    [switch] $PassThru,
    [switch] $Progress
)

while ($true) {
    $Url | ForEach-Object {
        $urlEntry = $_
        $ms = Measure-Command { 
            try {
                $progressBackup = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest $urlEntry -TimeoutSec ([int](($ThresholdMs * 2) / 1000))
                $ProgressPreference = $progressBackup
            } catch {
            } 
        } `
        | Select-Object -ExpandProperty TotalMilliseconds

        $distance = " " * 3
        $percentage = ($ms / $ThresholdMs) * 100

        $result = [PSCustomObject]@{
            Date                = Get-Date
            Measured            = $ms
            Threshold           = $ThresholdMs
            ThresholdReached    = $ms -gt $ThresholdMs
            ThresholdPercentage = $percentage
            Percentage          = [Math]::Min($percentage, 100)
            Url                 = $urlEntry
        }

        if ($Alarm -and $result.ThresholdReached) {
            [Console]::Beep($AlarmFrequency, 100)
        }

        if ($PassThru) {
            $result
        } else {
            if ($Progress) {
                $progressColorBackup = $host.PrivateData.ProgressBackgroundColor
                if ($result.ThresholdReached) {
                    $host.PrivateData.ProgressBackgroundColor = "red"
                }

                $progressId = [array]::IndexOf($Url, $urlEntry)

                Write-Progress `
                    -Activity "Measure Website" `
                    -Status ("Response Time: {0} ms ({1:0.00} % of {2} ms)" -f $result.Measured, $result.ThresholdPercentage, $result.Threshold) `
                    -PercentComplete $result.Percentage `
                    -CurrentOperation $urlEntry `
                    -Id $progressId

                $host.PrivateData.ProgressBackgroundColor = $progressColorBackup

                if ($result.ThresholdReached) {
                    $message = $result.Date.ToString() `
                        + $distance + ("{0,6:0} ms" -f [Math]::Abs($result.Measured)) `
                        + $distance + $urlEntry

                    Write-Host $message -ForegroundColor Red
                }
            } else {
                $suffix = ""

                $defaultFgColor = $host.UI.RawUI.ForegroundColor
                $msColor = if ($result.ThresholdReached) {
                    [ConsoleColor]::Red 
                } else {
                    [ConsoleColor]::Green 
                }
                $barColor = if ($result.ThresholdReached) {
                    [ConsoleColor]::Red 
                } else {
                    $defaultFgColor 
                }
                $formattedMilliseconds = "{0,6:0}" -f [Math]::Abs($result.Measured)

                Write-Host ($result.Date.ToString() + $distance) -NoNewline
                Write-Host ($formattedMilliseconds + $distance) -NoNewline -ForegroundColor $msColor
                
                $barMaxSegments = $host.UI.RawUI.WindowSize.Width - $host.UI.RawUI.CursorPosition.X - 2;
                $barSegments = ($barMaxSegments / 100) * $result.Percentage #$ms / 10
                if ($barSegments -gt $barMaxSegments) {
                    $suffix = "…"
                }

                $barSegments = [Math]::Min($barSegments, $barMaxSegments)
                $bar = ("#" * $barSegments) + $suffix;
                Write-Host $bar -ForegroundColor $barColor
            }
        }
    }

    Start-Sleep -Seconds 5
}