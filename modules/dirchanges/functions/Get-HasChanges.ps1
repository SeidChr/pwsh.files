param(
    [string] $Key,
    [string] $Path = ".",
    [string] $Filter = ""
)

$lastWriteTimeDisk = Get-LastWriteTime -Filter $Filter -Path $Path
$lastWriteTimeEnv = [Environment]::GetEnvironmentVariable("LASTCHANGES_$Key", "Process")

return ($lastWriteTimeEnv -ne $lastWriteTimeDisk)