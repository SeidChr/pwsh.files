function Start-NestedShell {
    param(
        [ScriptBlock]$command,
        $arguments
    )

    $exe = (get-process -Id $pid | Select-Object -ExpandProperty Path)
    if ($command) {
        if ($arguments) {
            . $exe -NoProfile -NoExit -NoLogo -Command $command -args $arguments
        } else {
            . $exe -NoProfile -NoExit -NoLogo -Command $command 
        }
    } else {
        . $exe -NoProfile -NoExit -NoLogo
    }
}

function Start-Profile {
    param( 
        [string]$path = $profile
    )
    Start-NestedShell `
        -arguments $path `
        -command { 
            param($path)
            . $path
        }
}

function Get-LocalProfilePath {
    param($location = (Get-Location), $profileId = "default")
    Join-Path $location ".pwsh" "$profileId.ps1"
}

# Recurse up the path, return possible profile locations on the way
# Locations will be in reverse order and beginning with the current user-profile
function Find-LocalProfilePath {
    param(
        $location = (Get-Location),
        $profileId = "default",
        [switch] $noFallback
    )

    # recurse up in the path
    function Get-ProfileLocations { 
        while ($location) { 
            Get-LocalProfilePath `
                -location $location `
                -profileId $profileId

            $location = $location | Split-Path -Parent
        }
        if (-not($noFallback)) {
            # standard profile at last
            $profile
        }
    }

    Get-ProfileLocations `
        | Where-Object { Test-Path $_ } `
        | Select-Object -First 1
}

function New-LocalProfile {
    param(
        $location = (Get-Location),
        $profileId = "default",
        $tag = $profileId,
        $message = "Local Profile `"$profileId`"",
        [switch] $PassThru
    )

    $path = Get-LocalProfilePath `
        -location $location `
        -profileId $profileId

    if (-not(Test-Path $path)) {
        New-Item -Path $path -ItemType File -Force
        Set-Content -Path $path -Value @"
. `$profile
Write-Host '$message'
`$originalPrompt=`$function:prompt
function prompt { (. `$originalPrompt '$tag') }
"@
    }

    $path
}

function Start-LocalShell {
    param($profileId = "default")
    Start-Profile `
        -path (Find-LocalProfilePath -profileId $profileId)
}

function Edit-LocalProfile {
    param(
        $location = (Get-Location),
        $profileId = "default"
    )

    $path = Find-LocalProfilePath -location $location -profileId $profileId -noFallback

    if ($path) {
        & code $path
    } else {
        Write-Error "No local profile found. Create one using `"New-LocalProfile`""
    }
}

Set-Alias -Name psh -Value Start-NestedShell
Set-Alias -Name lsh -Value Start-LocalShell

function Get-VsCodeProfileLocation {
    param($Path = (Get-Location))
    Join-Path $path ".vscode" "psprofile.ps1"
}

function Read-VsCodeLocalProfile {
    param($local:Path = (Get-Location))
    $local:vsCodeProfilePath = Get-VsCodeProfileLocation $local:Path
    if (Test-Path $local:vsCodeProfilePath) {
        . $local:vsCodeProfilePath
    }
}

function Initialize-VSCodeProfile {
    param($local:Path = (Get-Location))

    Set-Variable -Name IsVsCode -Value $true -Scope Global
    . Read-VsCodeLocalProfile $local:Path
}

function Test-VsCode {
    $callingProcess = Get-CallingProcess
    $callingProcess -and ($callingProcess.ProcessName -eq "Code")
}