param([switch]$NoCheckout)
# iwr -Uri 'https://raw.githubusercontent.com/SeidChr/pwsh.files/master/setup/install.ps1' -Headers @{"Cache-Control"="no-cache"} | iex

$account = "SeidChr"
$repository = "pwsh.files"
$destination = Join-Path ~ .pwsh
$githubBaseUrl = "https://github.com/$account/$repository"

if ($NoCheckout) {
    $version = "master"

    $url = "$githubBaseUrl/archive/$version.zip"
    $downloadPath = Join-Path $env:TEMP dotfiles "$version.zip"
    $unzipPath = Join-Path $env:TEMP dotfiles $version

    New-Item -ItemType Directory -Force -Path (Split-Path $downloadPath -Parent)
    Invoke-WebRequest -Uri $url -OutFile $downloadPath

    Get-Item $downloadPath | Unblock-File

    Expand-Archive -Path $downloadPath -DestinationPath $unzipPath -Force

    $extractedFilesFilter = "$unzipPath/$repository-$version/*"
    Copy-Item $extractedFilesFilter -Destination $destination -Recurse -Force

    #Remove-Item $downloadPath

    # iwr -Uri 'https://raw.githubusercontent.com/SeidChr/pwsh.files/master/setup/install.ps1' | iexup/install.ps1' | iex
} else {
    $profilePath = Join-Path $destination profile.ps1
    $command = ". $profilePath"
    & git clone "$githubBaseUrl.git" $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($destination)
    if (-not (Test-Path $PROFILE)) {
        New-Item $PROFILE -Force
    }
    if (!(Get-Content $PROFILE | Out-String).Contains($command)) {
        Add-Content $PROFILE -Value $command
    }
}

# load profile
. $PROFILE
