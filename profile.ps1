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