function Get-LastWriteTime {
    param(
        [string] $filter = "",
        [string] $path = "."
    )

    Get-ChildItem -Directory $path -Recurse -Filter $filter | % { $_.LastWriteTimeUtc } | Sort-Object -Descending -Top 1
    #Get-ChildItem $path -Recurse -Filter $filter | % { $_.LastWriteTimeUtc } | Measure -Maximum
}

# . $profile; $block = { 1..20 | % { $wait = (Get-Random -Maximum 3 -Minimum 0); Start-Sleep $wait ; Write-Output "$_ $wait" }}; Start-Parallel $block,$block,$block,$block;
function Start-Parallel {
    param(
        [ScriptBlock[]]
        [Parameter(Position = 0)]
        $ScriptBlock,

        [Object[]]
        [Alias("arguments")]
        $parameters
    )

    $jobs = $ScriptBlock | ForEach-Object { Start-Job -ScriptBlock $_ -ArgumentList $parameters }
    $colors = "Blue", "Red", "Cyan", "Green", "Magenta"
    $colorCount = $colors.Length

    try {
        while (($jobs | Where-Object { $_.State -ieq "running" } | Measure-Object).Count -gt 0) {
            $jobs | ForEach-Object { $i = 1 } {
                $fgColor = $colors[($i - 1) % $colorCount]
                $out = $_ | Receive-Job
                $out = $out -split [System.Environment]::NewLine
                $out | ForEach-Object {
                    Write-Host "$i> "-NoNewline -ForegroundColor $fgColor
                    Write-Host $_
                }

                $i++
            }
        }
    } finally {
        Write-Host "Stopping Parallel Jobs ..." -NoNewline
        $jobs | Stop-Job
        $jobs | Remove-Job -Force
        Write-Host " done."
    }
}