#Requires -Version 7.0

$taskName = 'UsbDisconnectScreensaverWatcher'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    throw 'This command must be executed in an elevated Terminal.'
}

$pwsh = (Get-Command pwsh -ErrorAction Stop).Source

$wt = (Get-Command wt.exe -ErrorAction Stop).Source
if (-not (Test-Path -LiteralPath $wt)) {
    $wt = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
}

if (-not (Test-Path -LiteralPath $wt)) {
    throw "Windows Terminal executable alias not found at: $wt"
}

$watcherScript = @"
Write-Host ''
Write-Host 'USB disconnect watcher scheduled task is running.'
Write-Host ''
Write-Host 'To unregister it, run:'
Write-Host '  Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false'
Write-Host 'in an elevated Terminal'
Write-Host ''
Watch-UsbDisconnectScreensaver -Identifier '*VID_046D&PID_C53A*' -Wildcard
"@

$encodedWatcherScript = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($watcherScript)
)

$wtArgs = @(
    'new-tab'
    '--title "USB Disconnect Watcher"'
    "`"$pwsh`""
    '-NoLogo'
    '-NoExit'
    '-EncodedCommand'
    $encodedWatcherScript
) -join ' '

$action = New-ScheduledTaskAction -Execute $wt -Argument $wtArgs
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal `
    -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel Limited

$settings = New-ScheduledTaskSettingsSet `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Starts the USB disconnect screensaver watcher in Windows Terminal at user logon.' `
    -Force

Write-Host "Registered scheduled task: $taskName"
Write-Host "Test it with:"
Write-Host "  Start-ScheduledTask -TaskName '$taskName'"
