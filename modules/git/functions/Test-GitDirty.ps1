param(
    $Path = (Get-Location)
)

!(Test-GitClean -Path $Path)

