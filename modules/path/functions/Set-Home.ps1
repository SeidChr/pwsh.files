# .SYNOPSIS
# rewirtes the user-home path for the current session
# updates $env:HOMEDRIVE, $env:HOMEPATH, $env:HOMESHARE, $HOME and ~ (Filesystem Home)
param(
    # The new Home-Path
    [Parameter(Mandatory)]
    [string] $Path,

    # Optional shared home-path.
    [string] $SharePath
)

$Path = $Path.TrimEnd('\/\\')

# set process-level home variables
$env:HOMEDRIVE = Split-Path -Path $Path -Qualifier
$env:HOMEPATH = Split-Path -Path $Path -NoQualifier

if ($SharePath) {
    $env:HOMESHARE = $SharePath
}

# Set and force overwrite of the $HOME variable
Set-Variable HOME $Path -Force

# Set the "~" shortcut value for the FileSystem provider
(Get-PSProvider 'FileSystem').Home = $Path