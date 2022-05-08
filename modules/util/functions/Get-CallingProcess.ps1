# .SYNOPSIS
# will return the first process that has not the
# same executable as the current powershell process

$leafProcess = Get-Process -Id $pid
$leafProcessPath = $leafProcess.Path

$parentProcess = $leafProcess.Parent;

while ($parentProcess) {
    if (-not ($parentProcess.Path -eq $leafProcessPath)) {
        return $parentProcess
    }
    $parentProcess = $parentProcess.Parent
}