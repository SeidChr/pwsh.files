param(
    $BaseBranch = 'develop',
    $Filter = 'feature*',
    $SoruceRemote = 'origin',
    $DestinationRemote = 'branch-backup',
    $RetentionDays = 365,
    [Switch] $WhatIf
)



$branches = . {
    Get-GitBranches -Merged $BaseBranch 
    Get-GitBranches |? { $_.LastCommit -lt [DateTime]::Now.AddDays(-$RetentionDays) }
} |? Branch -like $Filter |% {
    if ($WhatIf) {
        Write-Host "Would migrate branch $($_.Branch) last commit $($_.LastCommit) by $($_.Author)"
    } else {
        Migrate-GitBranch -BranchName $_.Branch -SourceRemote $SoruceRemote -DestinationRemote $DestinationRemote -Cleanup
    }
}


