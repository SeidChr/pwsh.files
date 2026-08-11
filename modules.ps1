$stopwatch = [System.Diagnostics.Stopwatch]::new()

try {
    Get-ChildItem (Join-Path $PSScriptRoot modules) | ForEach-Object {
        $module = $_
        $stopwatch.Restart()

        try {
            Import-Module -Force -DisableNameChecking -Name $module # -Verbose
        } finally {
            $stopwatch.Stop()
        }

        if ($stopwatch.Elapsed.TotalSeconds -gt 1) {
            Write-Warning ("Module '{0}' took {1:N2} seconds to load." -f $module.Name, $stopwatch.Elapsed.TotalSeconds)
        }
    }
} finally {
    $stopwatch = $null
}
