param(
    [ScriptBlock[]]
    [Parameter(Position = 0)]
    $ScriptBlock,

    [Object[]]
    [Alias("arguments")]
    $parameters,

    [Alias("sleep")]
    $pollSleepMilliseconds = 250,

    [Alias("init")]
    [scriptblock] $initializationScript,

    [Alias("input")]
    [Object]$inputObject
)

$jobs = $ScriptBlock | ForEach-Object { 
    Start-Job -ScriptBlock $_ -InitializationScript $initializationScript -ArgumentList $parameters -InputObject $input
}

try {
    while (($jobs | Where-Object { $_.State -ieq "running" } | Measure-Object).Count -gt 0) {
        Write-JobOutput -jobs $jobs
        # process needs some time to breathe
        Start-Sleep -Milliseconds $pollSleepMilliseconds
    }
} finally {
    Write-Host "Stopping Parallel Jobs ..."
    $jobs | Stop-Job
    Write-JobOutput -jobs $jobs
    $jobs | Remove-Job -Force
    Write-Host "Stopped all jobs."
}