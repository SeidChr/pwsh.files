
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
    }
    else {
        . $exe -NoProfile -NoExit -NoLogo
    }
}

function Start-Profile {
    param( $path = $profile )
    Start-NestedShell `
        -command { param($path); . $path } `
        -arguments $path
}

function Start-LocalShell {
    Start-Profile "$PSScriptRoot/localProfile.ps1"
}

Set-Alias -Name psh -Value Start-NestedShell
# folder shell / local shell
Set-Alias -Name fsh -Value Start-LocalShell
Set-Alias -Name lsh -Value Start-LocalShell
