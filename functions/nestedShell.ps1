
function Start-NestedShell {
    param ([ScriptBlock]$command)
    Write-Host "command: $command"
    $exe = (get-process -Id $pid | Select-Object -ExpandProperty Path)
    if ($command) {
        . $exe -NoProfile -NoExit -NoLogo -Command "$command"
    }
    else {
        . $exe -NoProfile -NoExit -NoLogo
    }
}

Set-Alias -Name psh -Value Start-NestedShell

function Start-Profile {
    param($path)
    Write-Host "PATH1" $path

    Start-NestedShell {
        Write-Host "PATH2" $path
        . $path
    }
}