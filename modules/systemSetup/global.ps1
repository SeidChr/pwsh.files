function Initialize-Windows10SystemClock {
    # set a registry value to show the seconds in the taskbar-clock
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -Value 1 -Type DWord
    
    # restarting explorer is required to actually show the seconds on the clock in the taskbar
    Stop-Process -Name explorer -Force
    Start-Process explorer
}

function Initialize-GamesDrive {
    $fileName = "StartGamesDrive.bat"
    $fileBody = "subst D: C:/Games"

    Invoke-Expression $fileBody

    # Autostart-Ordner des aktuellen Benutzers ermitteln
    $startupFolder = [Environment]::GetFolderPath("Startup")

    # Pfad zur Batch-Datei definieren
    $batchFilePath = Join-Path -Path $startupFolder -ChildPath $fileName

    # Überprüfen, ob die Batch-Datei bereits vorhanden ist
    if (Test-Path -Path $batchFilePath) {
        Write-Host "Games-Drive Autostart File already exists: $batchFilePath"
    } else {
        # Batch-Datei schreiben
        Set-Content -Path $batchFilePath -Value $fileBody -Force

        # Ausgabe zur Bestätigung
        Write-Host "Game-Drive Autostart File Created: $batchFilePath"
    }
}

function Initialize-CoreSoftware {
    @(
        #'Microsoft.PowerShell'
        'Git.Git'
        'Microsoft.WindowsTerminal'
        'Microsoft.Sysinternals'
        'Microsoft.VisualStudioCode'
        'Discord.Discord'
        '9PF0ZF86W5HK' # passwarden
        'Logitech.GHUB'
        'Elgato.StreamDeck'
        'Synology.DriveClient' # sync
        
        'Valve.Steam'
        'CloudImperiumGames.RSILauncher' # starcitizen
    ) |% {
        winget install $_ --accept-package-agreements
    }

    # todos:
    # gamebar
            # 'GIGABYTE.GigabyteControlCenter' -> dl appcenter instead
        # https://www.gigabyte.com/Motherboard/X570-AORUS-ULTRA-rev-11-12/support#support-dl-utility
    # |% { winget install $_ --accept-package-agreements }
}

# # Define the folder to add as a Steam library
# $libraryFolder = "D:\Steam"  # Replace with your desired folder path

# # Define the Steam library configuration file path
# $steamConfigPath = "$env:ProgramFiles(x86)\Steam\config\libraryfolders.vdf"

# # Check if the Steam configuration file exists
# if (Test-Path -Path $steamConfigPath) {
#     # Read the existing configuration
#     $configContent = Get-Content -Path $steamConfigPath

#     # Check if the folder is already added
#     if ($configContent -notcontains $libraryFolder) {
#         # Add the folder to the configuration
#         $configContent += "`"$libraryFolder`""
#         Set-Content -Path $steamConfigPath -Value $configContent

#         Write-Host "The folder has been successfully added to the Steam library configuration."
#     } else {
#         Write-Host "The folder is already present in the Steam library configuration."
#     }
# } else {
#     Write-Host "Steam configuration file not found. Please ensure Steam is installed."
# }