. $PSScriptRoot/modules.ps1

$global:shellNestingLevel = Get-ShellNestingLevel
$global:sharing = $false

if (Test-VsCode) {
    . Initialize-VSCodeProfile
}

. $PSScriptRoot/prompt.ps1

Write-Host PWSH $($psversiontable.PSEdition) $($psversiontable.PSVersion)
if (Test-GitDirty -Path $PSScriptRoot) {
    Write-Host "Your PS-Profile has uncommitted local Changes!" -ForegroundColor Red
}

# allow calling scripts without '.\' prefix
#$env:PATH += [System.IO.Path]::PathSeparator + "."
Add-Path "."

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function ForwardWord
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# https://stackoverflow.com/a/52485269/1280354
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-7.2
# Store previous command's output in $__
$PSDefaultParameterValues['Out-Default:OutVariable'] = '__'
