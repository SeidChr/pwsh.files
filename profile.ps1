. $PSScriptRoot/functions.ps1
. $PSScriptRoot/prompt.ps1

Write-Host PWSH $($psversiontable.PSEdition) $($psversiontable.PSVersion)

# allow calling scripts without '.\' prefix
$env:path = $env:path + [System.IO.Path]::PathSeparator + "."

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete