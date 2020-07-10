function Update-Dotfiles {
    Push-Location "~/.pwsh"
    try {
        & git pull
    } finally {
        Pop-Location
    }
}

function Get-DockerShell {
    param(
        $image = "debian",
        $entrypoint,
        $shell #alias for entrypoint
    )

    if (![string]::IsNullOrWhiteSpace($shell)) { 
        $entrypoint = $shell
    }

    if (![string]::IsNullOrWhiteSpace($entrypoint)) {
        & docker run -it --rm --entrypoint $entrypoint $image
    } else {
        & docker run -it --rm $image
    }
}

function Get-Path {
    $pathParts = $env:PATH -split [System.IO.Path]::PathSeparator
    $cleanedPath = New-Object System.Collections.Generic.List[string]
    $pathParts | Where-Object { ![string]::IsNullOrWhiteSpace($_) } `
    | ForEach-Object {
        $newPart = $_.Trim("/").Trim("\")
        if ($cleanedPath -cNotContains $newPart)
        {
            $cleanedPath.Add($newPart)
        }
    }

    return $cleanedPath.ToArray()
}

function Repair-Path {
    $newPath = (Get-Path) -join [System.IO.Path]::PathSeparator
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "Process")
    $env:PATH
}

function Add-Path {
    param([string] $value)
    $currentPathValues = Get-Path
    if ($currentPathValues -cNotContains $value) {
        $env:PATH = ($currentPathValues + $value) -join [System.IO.Path]::PathSeparator
        #[System.Environment]::SetEnvironmentVariable("PATH", $newPath, "Process")
        # do not use the Get-Path output, or it will re-order 
        # the content, which is not desireable
        #$env:PATH += [System.IO.Path]::PathSeparator + $value
    }
}

function Edit-Profile {
    & code (Resolve-Path ~/.pwsh)
}

function Get-LastWriteTime {
    param(
        [string] $filter = "",
        [string] $path = "."
    )

    Get-ChildItem -Directory $path -Recurse -Filter $filter | % { $_.LastWriteTimeUtc } | Sort-Object -Descending -Top 1
    #Get-ChildItem $path -Recurse -Filter $filter | % { $_.LastWriteTimeUtc } | Measure -Maximum
}
