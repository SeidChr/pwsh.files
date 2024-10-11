param(
    [Parameter(Position = 0, Mandatory)]
    [ScriptBlock[]] $ScriptBlock,

    # z.B.: (,@(1, 2))
    [Alias("Arguments")]
    [Object[][]] $Parameters = @(),

    [Alias("Sleep")]
    [int] $PollSleepMilliseconds = 250,

    [Alias("Init")]
    [scriptblock] $InitializationScript,

    [Alias("Input")]
    [Object] $InputObject
)

$jobs = for ($i=0; $i -lt $ScriptBlock.Length; $i++) { 
    Start-Job -ScriptBlock $ScriptBlock[$i] -InitializationScript $InitializationScript -ArgumentList $Parameters[$i] -InputObject $InputObject
}

try {
    while (($jobs | Where-Object { $_.State -ieq "running" } | Measure-Object).Count -gt 0) {
        Write-JobOutput -jobs $jobs
        # process needs some time to breathe
        Start-Sleep -Milliseconds $pollSleepMilliseconds
    }
} finally {
    Write-Host "Stopping Parallel Jobs... ⏳"
    $jobs | Stop-Job
    Write-JobOutput -jobs $jobs
    $jobs | Remove-Job -Force
    Write-Host "Stopped Parallel Jobs! ✔"
}