param([switch]$NoCheckout)
# iwr -Uri 'https://raw.githubusercontent.com/SeidChr/pwsh.files/master/setup/install.ps1' | iex

$account = "SeidChr"
$repository = "pwsh.files"
$destination = "~\.pwsh"
$githubBaseUrl = "https://github.com/$account/$repository"

if ($NoCheckout) {
    $version = "master"

    $url = "$githubBaseUrl/archive/$version.zip"
    $downloadPath = "$env:TEMP\dotfiles\$version.zip"
    $unzipPath = "$env:TEMP\dotfiles\$version"

    New-Item -ItemType Directory -Force -Path (Split-Path $downloadPath -Parent)
    Invoke-WebRequest -Uri $url -OutFile $downloadPath

    Get-Item $downloadPath | Unblock-File

    Expand-Archive -Path $downloadPath -DestinationPath $unzipPath -Force

    $extractedFilesFilter = "$unzipPath/$repository-$version/*"
    Copy-Item $extractedFilesFilter -Destination $destination -Recurse -Force

    #Remove-Item $downloadPath

    # iwr -Uri 'https://raw.githubusercontent.com/SeidChr/pwsh.files/master/setup/install.ps1' | iexup/install.ps1' | iex
} else {
    $command = ". $destination\profile.ps1"
    & git clone "$githubBaseUrl.git" ($destination | Resolve-Path)
    if (!(Get-Content $profile | Out-String).Contains($command)) {
        Add-Content $profile -Value $command
    }
}
