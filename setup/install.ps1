$account = "SeidChr"
$repository = "pwsh.files"
$destination = "~/.pwsh"
$version = "master"

$url = "https://github.com/$account/$repository/archive/$version.zip"
$downloadPath = "$env:TEMP\dotfiles\$version.zip"
$unzipPath = "$env:TEMP\dotfiles\$version"

New-Item -ItemType Directory -Force -Path (Split-Path $downloadPath -Parent)
Invoke-WebRequest -Uri $url -OutFile $downloadPath

Get-Item $downloadPath | Unblock-File

Expand-Archive -Path $downloadPath -DestinationPath $unzipPath -Force

#$extractedFilesFilter = "$unzipPath/$repository-$version/**/*.*"
#Get-ChildItem -Path $extractedFilesFilter -Recurse | Move-Item -Destination $destination -WhatIf
$extractedFilesFilter = "$unzipPath/$repository-$version/*"
Copy-Item $extractedFilesFilter -Destination $destination -Recurse -Force
#Move-Item -Path $extractedFilesFilter -Destination $destination -Force

#Remove-Item $downloadPath

# iwr -Uri 'https://raw.githubusercontent.com/SeidChr/pwsh.files/master/setup/install.ps1' | iex