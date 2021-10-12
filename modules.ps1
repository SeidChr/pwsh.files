Get-ChildItem (Join-Path $PSScriptRoot modules) | ForEach-Object {
    Import-Module -Force -DisableNameChecking -Name $_ # -Verbose
}