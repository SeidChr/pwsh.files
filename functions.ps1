function Update-Dotfiles {
    Push-Location "~/.pwsh"
    try {
        & git pull
    } finally {
        Pop-Location
    }
}

function Get-DockerShell {
    param(
        $image = "debian",
        $entrypoint,
        $shell #alias for entrypoint
    )

    if (![string]::IsNullOrWhiteSpace($shell)) { 
        $entrypoint = $shell
    }

    if (![string]::IsNullOrWhiteSpace($entrypoint)) {
        & docker run -it --rm --entrypoint $entrypoint $image
    } else {
        & docker run -it --rm $image
    }
}