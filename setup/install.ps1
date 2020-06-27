$account = "SeidChr"
$repository = "pwsh.files"

$url = "https://github.com/$account/$repository/archive/master.zip"
$download_path = "$env:TEMP\dotfiles\master.zip"

New-Item -ItemType Directory -Force -Path (Split-Path $download_path -Parent)
Invoke-WebRequest -Uri $url -OutFile $download_path

Get-Item $download_path | Unblock-File

Expand-Archive -Path $download_path -DestinationPath ~/.pwsh -Force

Remove-Item $download_path

# iwr -Uri 'https://raw.githubusercontent.com/SeidChr/pwsh.files/master/setup/install.ps1' | iex