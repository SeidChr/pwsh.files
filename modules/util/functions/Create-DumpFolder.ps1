param(
    [string] $Name,
    [switch] $Pwsh,
    [switch] $Console
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
# $folders = Get-DumpFolder
# $groupedFolders = $folders | Group-Object -Property Type

# # Query available Dump folders (non-desktop)
# $Selection = $groupedFolders.Name + "Desktop"
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

if ($Console) {
    Push-Location $newFolderPath
    try {
        dotnet new sln --name $Name
        dotnet new console --name $Name
        dotnet new gitignore
    } finally {
        Pop-Location
    }
}

code "$newFolderPath"
