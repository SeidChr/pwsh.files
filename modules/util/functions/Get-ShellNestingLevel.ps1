# .Synopsis
# counts how many instance of powershell are in the process hirarchy directly above this one.
# pwsh (nesting level 0)
# |> pwsh (nesting level 1)
#    |> pwsh (nesting level 2)

$leafProcess = Get-Process -Id $pid
$leafProcessPath = $leafProcess.Path
$nestingLevel = 0

$parentProcess = $leafProcess.Parent;
while ($parentProcess) {
    if ($parentProcess.Path -eq $leafProcessPath) {
        $nestingLevel++;
    } else {
        break
    }

    $parentProcess = $parentProcess.Parent;
}

$nestingLevel

