param(
    [string] $Name,
    [switch] $Pwsh,
    [switch] $Console,
    [switch] $Git
)

if (-not $Name) {
    $Name = Read-Host "Identifier or Name"
}

$titleCaseName = [Char]::ToUpper($name[0]) + ($name.Substring(1))

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
        $slnName = $titleCaseName
        $prjName = $titleCaseName
        $tstName = "$titleCaseName.Tests"

        dotnet new sln     --name $slnName
        dotnet new console --name $prjName
        dotnet new xunit   --name $tstName
        dotnet sln add $prjName
        dotnet sln add $tstName
        dotnet     add $tstName reference $prjName
        
        Invoke-WebRequest -Uri "https://gist.githubusercontent.com/SeidChr/60c54944920f3f5c47c4b2b79a552023/raw" -OutFile ".editorconfig"
    } finally {
        Pop-Location
    }
}

if ($Git) {
    Push-Location $newFolderPath

    try {
        if ($Console) {
            dotnet new gitignore
        }

        git init
        git add *
        git commit -m "Intital Commit for $titleCaseName"
    } finally {
        Pop-Location
    }
}

code "$newFolderPath"
