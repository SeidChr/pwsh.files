# Recurse up the path, return possible profile locations on the way
# Locations will be in reverse order and beginning with the current user-profile
function Get-LocalProfile {
    param($location = (Get-Location))
    if (-not($location)) {
        $profile
    } else {
        Get-LocalProfile -location ($location | Split-Path -Parent)
        Join-Path $location ".pwsh" "local.ps1"
    }
}

# dot-source all profiles that can be found
Get-LocalProfile `
    | Where-Object { Test-Path $_ } `
    | ForEach-Object { . $_ }