param(
    [string] $Key,
    [string] $Filter = "",
    [string] $Path = "."
)

$lastWriteTime = Get-LastWriteTime -Filter $Filter -Path $Path
[Environment]::SetEnvironmentVariable("LASTCHANGES_$Key", $lastWriteTime, "Process")