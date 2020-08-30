. $PSScriptRoot\functions\automation.ps1
. $PSScriptRoot\functions\docker.ps1
. $PSScriptRoot\functions\path.ps1

function Update-Profile {
    Push-Location "~/.pwsh"
    try {
        & git pull
    } finally {
        Pop-Location
    }
}

function Edit-Profile {
    & code (Resolve-Path ~/.pwsh)
}