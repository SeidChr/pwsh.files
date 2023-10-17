param(
    [string] $Name,
    [switch] $Pwsh
)

# Create Folder With name "<Date> <Name>"
## Where
## What Name

if (-not $Name) {
    $Name = Read-Host "Identifier or Name"
}

# Desktop / Sync / OneDrive ?
##i Desktop is a dump folder in itself. location is queriable through windows.
## Desktop -|

## Sync
### Find Sync Folder

## OneDrive
### Find OneDrive Folder
#### private or company OneDrive

# Query available Dump folders (non-desktop)
# $Selection = "Desktop", "Code Dump", "Work Dump", "Private Dump" 
#     | ForEach-Object { New-Object System.Management.Automation.Host.ChoiceDescription $_ }
# $Host.UI.PromptForChoice($Caption, $Message, $Selection, $Default)

$date = Get-Date -Format "yyyyMMdd"

$basePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
## Create Folder
## Open Folder

$newFolderPath = Join-Path $basePath "$date $name"
if (-not (Test-Path $newFolderPath)) {
    $null = New-Item -Path $newFolderPath -ItemType Directory
}

if ($Pwsh) {
    $scriptFilePath = Join-Path $newFolderPath "script.ps1"
    if (-not (Test-Path $scriptFilePath)) {
        $null = New-Item -Path $scriptFilePath -ItemType File
    }
}

code "$newFolderPath"
