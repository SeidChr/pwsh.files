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
        # essentials
        #'Microsoft.PowerShell'      # must be here before this runs ... can only install manually
        # install manually: winget install 'Microsoft.PowerShell' --accept-package-agreements
        'Git.Git'                    # to download and refresh this very profile. also devdw
        'Microsoft.WindowsTerminal'
        '7zip.7zip'
        'Docker.DockerDesktop'
        'Microsoft.Sysinternals'
        'Microsoft.PowerToys'
        'Synology.DriveClient'       # sync
        'Elgato.StreamDeck'          # onedrive dump private 20250320
        'Logitech.GHUB'              # setting suploaded in profile and can be applied from there
        '9PF0ZF86W5HK'               # passwarden
        'Microsoft.OneDrive'         # update default version, as of problems with login
        'Discord.Discord'
        
        # dev
        'DevToys-app.DevToys'
        'Microsoft.VisualStudioCode'
        
        # gaming
        'Valve.Steam'
        'GOG.Galaxy'
        'Amazon.Games'
        'EpicGames.EpicGamesLauncher'
        'ElectronicArts.EADesktop'
        'Ubisoft.Connect'
        'CloudImperiumGames.RSILauncher' # starcitizen
        
        # work
        # 'DominikReichl.KeePass'
        # "Microsoft.VisualStudio.2022.Enterprise"
        # "Axosoft.GitKraken"
        # "ScooterSoftware.BeyondCompare4"
        # "Microsoft.VisualStudioCode"
        # "mRemoteNG.mRemoteNG"
    ) | ForEach-Object {
        winget install $_ --accept-package-agreements
    }

    # todos:
    # gamebar
    # ptouch editor

                # 'GIGABYTE.GigabyteControlCenter' -> dl appcenter instead
        # https://www.gigabyte.com/Motherboard/X570-AORUS-ULTRA-rev-11-12/support#support-dl-utility
    # |% { winget install $_ --accept-package-agreements }
}

function Start-ScreenSaver {
    # base46 for streamdeck:
    # encoded string must be unicode/UTF-16LE
    # pwsh -EncodedCommand ([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(@"
    #   (Add-Type '[DllImport("user32.dll")]public static extern int PostMessage(int a, int b, int c, int d);' -Name a -Pas)::PostMessage(-1,0x0112,0xF170,2) | Out-Null
    #   "@)))
    # pwsh -w Hidden -nop -noni -nol -EncodedCommand KABBAGQAZAAtAFQAeQBwAGUAIAAnAFsARABsAGwASQBtAHAAbwByAHQAKAAiAHUAcwBlAHIAMwAyAC4AZABsAGwAIgApAF0AcAB1AGIAbABpAGMAIABzAHQAYQB0AGkAYwAgAGUAeAB0AGUAcgBuACAAaQBuAHQAIABQAG8AcwB0AE0AZQBzAHMAYQBnAGUAKABpAG4AdAAgAGEALAAgAGkAbgB0ACAAYgAsACAAaQBuAHQAIABjACwAIABpAG4AdAAgAGQAKQA7ACcAIAAtAE4AYQBtAGUAIABhACAALQBQAGEAcwApADoAOgBQAG8AcwB0AE0AZQBzAHMAYQBnAGUAKAAtADEALAAwAHgAMAAxADEAMgAsADAAeABGADEANwAwACwAMgApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAA=
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pwsh?view=powershell-7.5#-encodedcommand---e---ec
    (Add-Type '[DllImport("user32.dll")]public static extern int PostMessage(int a, int b, int c, int d);' -Name a -Pas)::PostMessage(-1,0x0112,0xF170,2) | Out-Null
}



# TODO:
# - Energy-Saving Settings to never turn off or hibernate, screen off: 15m
# - find and import streamdeck profile (see next point)
# - get onedrive path, install app profiles from onedrive after setting onderive up correctly
# - add steam library folder from games drive to steam and make it default


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

