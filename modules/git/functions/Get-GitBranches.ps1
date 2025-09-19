param(
    [string] $Remote = 'origin', 
    
    $Merged = 'All'
)

$mergeArgument = switch ($Merged) {
    'All' { '' }
    'No' { '--no-merged' }
    default { "--merged $Merged" }
}

filter invoke { 
    Write-Host -NoNewline -ForegroundColor Blue '> '
    Write-Host $_
    Invoke-Expression $_ 
}

"git for-each-ref refs/remotes/$Remote --format='%(committerdate:iso-strict) %(refname:strip=3) %(authorname)' --sort committerdate --exclude=refs/remotes/$Remote/HEAD $mergeArgument" | invoke | ForEach-Object {
    $parts = $_ -split ' ', 3
    [PSCustomObject]@{Branch=$parts[1];LastCommit=[DateTime]::Parse($parts[0]);Author=$parts[2]}
}