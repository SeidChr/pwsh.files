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