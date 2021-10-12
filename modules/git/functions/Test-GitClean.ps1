param(
    $Path = (Get-Location)
)

$command = "git -C `"$Path`" status -z"
# Write-Host $command

$backupExitCode = $global:LASTEXITCODE
$statusString = Invoke-Expression $command | Out-String
$global:LASTEXITCODE = $backupExitCode

!($statusString)