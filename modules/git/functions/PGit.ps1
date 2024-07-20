param(
    [Parameter(Mandatory)]
    $Id,
    [Parameter(Mandatory)]
    $IsAncestorOf
)
$null = git merge-base --is-ancestor $Id $IsAncestorOf
return $?
