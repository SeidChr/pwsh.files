param(
    [Parameter(ValueFromPipeline)]
    $BranchName,
    $SourceRemote = 'origin', 
    $DestinationRemote = 'branch-backup',
    [switch]$Cleanup
)

begin {
    filter invoke { 
        Write-Host -NoNewline -ForegroundColor Blue '> '
        Write-Host $_
        Invoke-Expression $_ 
    }
}

process {
    if ($_) {
        $BranchName = $_
    }

    "git fetch $SourceRemote $($BranchName):$($BranchName)" | invoke

    try {
        "git push $DestinationRemote $($BranchName):$($BranchName)" | invoke
        if ($Cleanup) {
            "git push -d $SourceRemote $BranchName" | invoke # Delete remote
            "git branch -D $BranchName"             | invoke # Delete local
        }
    } catch {
        Write-Error "Error during push."
    }
}