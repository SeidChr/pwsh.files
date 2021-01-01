function Get-Path {
    $pathParts = $env:PATH -split [System.IO.Path]::PathSeparator
    $cleanedPath = New-Object System.Collections.Generic.List[string]
    $pathParts `
        | Where-Object { ![string]::IsNullOrWhiteSpace($_) } `
        | ForEach-Object {
        $newPart = $_.TrimEnd('\/\\')
        if ($cleanedPath -cNotContains $newPart) {
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
    param(
        # A path value to be added.
        [string] $Value,

        # Will add the entry to the beginning of the path, instead of the end.
        [switch] $Prefix,

        # Will resolve the $value to an existing path, before adding it.
        [switch] $Resolve
    )

    if ($resolve) {
        $value = Resolve-Path $value
    }

    $currentPathValues = Get-Path
    if ($currentPathValues -cNotContains $value) {
        $newPath = if ($prefix) { (,$value) + $currentPathValues } else { $currentPathValues + $value }
        $env:PATH = $newPath -join [System.IO.Path]::PathSeparator
    }
}

function Set-Home {
    param(
        [string] $Path,
        [string] $SharePath
    )

    $Path = $Path.TrimEnd('\/\\')

    # set process-level home variables
    $env:HOMEDRIVE = Split-Path -Path $Path -Qualifier
    $env:HOMEPATH = Split-Path -Path $Path -NoQualifier

    if ($SharePath) {
        $env:HOMESHARE = $SharePath
    }

    # Set and force overwrite of the $HOME variable
    Set-Variable HOME $Path -Force

    # Set the "~" shortcut value for the FileSystem provider
    (Get-PSProvider 'FileSystem').Home = $Path
}