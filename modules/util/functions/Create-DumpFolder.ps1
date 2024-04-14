param(
    [string] $Name,
    [switch] $Pwsh,
    [switch] $Console
)

if (-not $Name) {
    $Name = Read-Host "Identifier or Name"
}

$date = Get-Date -Format "yyyyMMdd"

$basePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

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
        $titleCaseName = [Char]::ToUpper($name[0]) + ($name.Substring(1))
        dotnet new sln --name $titleCaseName
        dotnet new console --name $titleCaseName
        dotnet new xunit --name "$titleCaseName.Tests"
        dotnet sln add $titleCaseName
        dotnet sln add "$titleCaseName.Tests"
        dotnet add "$titleCaseName.Tests" reference $titleCaseName
        dotnet new gitignore
        Invoke-WebRequest -Uri "https://gist.githubusercontent.com/SeidChr/60c54944920f3f5c47c4b2b79a552023/raw" -OutFile ".editorconfig"
    } finally {
        Pop-Location
    }
}

code "$newFolderPath"
