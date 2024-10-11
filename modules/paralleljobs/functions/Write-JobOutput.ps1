
# . $profile; $block = { 1..20 | % { $wait = (Get-Random -Maximum 3 -Minimum 0); Start-Sleep $wait ; Write-Output "$_ $wait" }}; Start-Parallel $block,$block,$block,$block;

param(
    $jobs,
    $colors = @("Blue", "Red", "Cyan", "Green", "Magenta")
)

$colorCount = $colors.Length

$jobs | ForEach-Object { 
    $i = 1 
} {
    $fgColor = $colors[($i - 1) % $colorCount]
    $out = $_ | Receive-Job -ErrorAction Continue
    $out = $out -split [System.Environment]::NewLine
    $out | ForEach-Object {
        Write-Host "$i> " -NoNewline -ForegroundColor $fgColor
        Write-Host $_
    }
    
    $i++
}