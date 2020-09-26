. $PSScriptRoot/functions.ps1
. $PSScriptRoot/nested/shell.ps1

$global:shellNestingLevel = Get-ShellNestingLevel

. $PSScriptRoot/prompt.ps1

Write-Host PWSH $($psversiontable.PSEdition) $($psversiontable.PSVersion)

# allow calling scripts without '.\' prefix
#$env:PATH += [System.IO.Path]::PathSeparator + "."
Add-Path "."

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete