$newPath = (Get-Path) -join [System.IO.Path]::PathSeparator

[System.Environment]::SetEnvironmentVariable("PATH", $newPath, "Process")

$env:PATH
