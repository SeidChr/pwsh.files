param(
    [Parameter(Mandatory)][string]$From, 
    [Parameter(Mandatory)][string]$To, 
    $Remote = "origin"
)

git fetch $Remote "$($To):$($From)"
