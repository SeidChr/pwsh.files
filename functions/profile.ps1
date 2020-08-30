function Update-Profile {
    Push-Location "~/.pwsh"
    try {
        & git pull
    } finally {
        Pop-Location
    }
}

function Open-Profile {
    param([switch] $online)
    if ($online) {
        Start-Process "https://github.com/SeidChr/pwsh.files"
    } else {
        & code (Resolve-Path ~/.pwsh)
    }
}

Set-Alias Edit-Profile Open-Profile
