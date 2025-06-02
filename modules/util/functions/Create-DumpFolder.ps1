param(
    [string] $Name,
    [switch] $Pwsh,
    [switch] $Console,
    [switch] $Web,
    [switch] $Lib,
    [switch] $Git,
    # clears out an possibly existing folder to start over
    [switch] $Clean
)

$script:errorActionPreference='Stop'

if (-not $Name) {
    $Name = Read-Host "Identifier or Name"
}

$titleCaseName = [Char]::ToUpper($name[0]) + ($name.Substring(1))

$date = Get-Date -Format "yyyyMMdd"

$basePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

$newFolderPath = Join-Path $basePath "$date $name"

$CreateSolution = $Console -or $Web -or $Lib

function InPath {
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [ScriptBlock] $ScriptBlock
    )

    Push-Location $Path
    try {
        . $ScriptBlock
    } finally {
        Pop-Location
    }

}

if (Test-Path $newFolderPath) {
    if ($Clean) {
        Remove-Item -Path $newFolderPath -Recurse -Force
    } else {
        throw "Path $newFolderPath already existing. Use '-Clean' to remove it."
    }
}

$null = New-Item -Path $newFolderPath -ItemType Directory

if ((Test-Path $newFolderPath) -and $Clean) {
    Remove-Item -Path $newFolderPath -Recurse -Force
    $null = New-Item -Path $newFolderPath -ItemType Directory
} 

if (-not (Test-Path $newFolderPath)) {
    $null = New-Item -Path $newFolderPath -ItemType Directory
}

if ($Pwsh) {
    $scriptFilePath = Join-Path $newFolderPath "script.ps1"
    if (-not (Test-Path $scriptFilePath)) {
        $null = New-Item -Path $scriptFilePath -ItemType File
    }
}


if ($CreateSolution) {
    Push-Location $newFolderPath
    try {
        dotnet new sln --name $titleCaseName
        Invoke-WebRequest -Uri "https://gist.githubusercontent.com/SeidChr/60c54944920f3f5c47c4b2b79a552023/raw" -OutFile ".editorconfig"
    } finally {
        Pop-Location
    }
}

if ($Lib) {
    InPath $newFolderPath {
        $prjName = "$titleCaseName.Library"
        $tstName = "$titleCaseName.Library.Tests"

        $script:libName = $prjName

        dotnet new classlib --name $prjName
        dotnet new xunit    --name $tstName
        dotnet sln add $prjName
        dotnet sln add $tstName
        dotnet     add $tstName reference $prjName
    }
}

if ($Console) {
    InPath $newFolderPath {
        $prjName = "$titleCaseName.Console"
        $tstName = "$titleCaseName.Console.Tests"

        dotnet new console --name $prjName
        if ($Lib) {
            dotnet add $prjName reference $script:libName
        }

        dotnet new xunit   --name $tstName

        dotnet sln add $prjName
        dotnet sln add $tstName
        dotnet     add $tstName reference $prjName
    }
}

if ($Web) {
    InPath $newFolderPath {
        $prjName = "$titleCaseName.Web"
        $tstName = "$titleCaseName.Web.Tests"

        dotnet new webapi --name $prjName
        if ($Lib) {
            dotnet add $prjName reference $script:libName
        }

        dotnet new xunit  --name $tstName
        dotnet sln add $prjName
        dotnet sln add $tstName
        dotnet     add $tstName reference $prjName
    }
}

if ($Git) {
    InPath $newFolderPath {
        if ($CreateSolution) {
            dotnet new gitignore
        }

        git init
        git add *
        git commit -m "Intital Commit for $titleCaseName"
    }
}

code "$newFolderPath"
