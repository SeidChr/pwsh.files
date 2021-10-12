param(
    [string] $Filter = "",
    [string] $Path = "."
)

$Path = Resolve-Path $Path
Write-Host $path

Get-ChildItem -Path $Path -Recurse `
    | ForEach-Object { $_.LastWriteTimeUtc } `
    | Sort-Object -Descending -Top 1