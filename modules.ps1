$moduleLoadTimes = [System.Collections.Generic.List[object]]::new()

$moduleStopwatch = [System.Diagnostics.Stopwatch]::new()
$overallStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    Get-ChildItem (Join-Path $PSScriptRoot modules) | ForEach-Object {
        $module = $_
        $moduleStopwatch.Restart()

        try {
            Import-Module -Force -DisableNameChecking -Name $module # -Verbose
        } finally {
            $moduleStopwatch.Stop()
            $moduleLoadTimes.Add([pscustomobject]@{
                Module       = $module.Name
                Milliseconds = [math]::Round($moduleStopwatch.Elapsed.TotalMilliseconds, 2)
            })
        }

        if ($moduleStopwatch.Elapsed.TotalSeconds -gt 1) {
            Write-Warning ("Module '{0}' took {1:N2} seconds to load." -f $module.Name, $moduleStopwatch.Elapsed.TotalSeconds)
        }
    }
} finally {
    $overallStopwatch.Stop()

    if ($overallStopwatch.Elapsed.TotalSeconds -gt 1) {
        Write-Warning ("Modules took {0:N2} milliseconds overall to load." -f $overallStopwatch.Elapsed.TotalMilliseconds)
        $moduleLoadTimes |
            Sort-Object Milliseconds -Descending |
            Format-Table Module, Milliseconds -AutoSize |
            Out-Host
    }

    $moduleStopwatch = $null
    $overallStopwatch = $null
    $moduleLoadTimes = $null
}
