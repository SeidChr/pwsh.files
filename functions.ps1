function Update-Dotfiles {
    param(
        $account = "SeidChr",
        $repository = "dotfiles"
    )

    $url = "https://github.com/$account/$repository/archive/master.zip"
    $download_path = "$env:TEMP\dotfiles\master.zip"

    Invoke-WebRequest -Uri $url -OutFile $download_path

    Get-Item $download_path | Unblock-File

    Expand-Archive -Path $download_path -DestinationPath ~/.pwsh -Force
    
    Remove-Item $download_path
}

function Get-DockerShell {
    param(
        $image = "debian",
        $entrypoint = "/bin/bash"
    )

    #& docker run -it --rm --entrypoint /bin/bash node
    & docker run -it --rm --entrypoint $entrypoint $image
}