<# .SYNOPSIS #>
function Add-GitHooks {
    param(
        # Creates git hooks only for the hooks that are located in the repo githooks folder
        [switch] $onlyExistingHooks, 
        # Clean all existing git hooks (in the git-folder) before updating them. not always required (only when hooks disappeared and you use the -onlyExistingHooks option)
        [switch] $clean,
        # changes the powershell executable which is called by the git hooks (will be called in path)
        [string] $powershellExecutableName = (get-process -Id $pid).Name,
        # where are the powerhell hooks located which git should use
        [string] $projectFolder = (Get-Location).Path,
        [string] $hooksFolder = (Join-Path $projectFolder "githooks")
    )

    $projectFolder = Resolve-Path $projectFolder
    $hooksFolder = Resolve-Path $hooksFolder

    $internalGitHooksFolder = Resolve-Path (Join-Path $projectFolder ".git" "hooks")
    
    # setting the hooks path seems to have no effect at all.
    #& git config --local core.hooksPath '.\githooks'; #'$GIT_WORK_TREE\githooks'

    # setup hooks path for git
    $hookNames = 'applypatch-msg', 'pre-applypatch', 'post-applypatch', 'pre-commit', `
        'pre-merge-commit', 'prepare-commit-msg', 'commit-msg', 'post-commit', 'pre-rebase', `
        'post-checkout', 'post-merge', 'pre-push', 'post-update', 'push-to-checkout', `
        'pre-auto-gc', 'post-rewrite', 'sendemail-validate';

    # limit hook names for testing
    #$hookNames = 'post-commit'

    if ($clean) {
        # clean all existing hooks. not always required (only when hooks disappeared and you use the -onlyExistingHooks option)
        $hookNames | ForEach-Object { 
            $hookPath = Join-Path $internalGitHooksFolder "$_"
            Write-Debug "Deleting $hookPath"
            Remove-Item $hookPath -ErrorAction SilentlyContinue
        }
    }

    if ($onlyExistingHooks) {
        # filter hooks to only create files with in-repo counterparts
        
        $hookNames = $hookNames | Where-Object { 
            $hookPath = Join-Path $hooksFolder "$_.ps1"
            $tested = Test-Path $hookPath
            Write-Debug "$($hookPath) Exists? -> $tested"
            $tested
        }
    }

    # place existing hooks
    $hookNames | ForEach-Object {
        $targetPath = Join-Path $hooksFolder "$_.ps1"
        $shTargetPath = $targetPath#.Replace("\", "/")
        $body = @"
#!/bin/sh
if [[ -f "$shTargetPath" ]]; then
    $powershellExecutableName "$shTargetPath" `$@
    exit `$?
fi
"@
        $internalHook =  Join-Path $internalGitHooksFolder $_

        Set-Content -Path $internalHook -Value $body
        Write-Host Created hook $(Resolve-Path $internalHook -Relative) pointing to $(Join-Path (Resolve-Path $hooksFolder -Relative) "$_.ps1")
    }
}

function Edit-GitCommits {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $name,

        [Parameter(Mandatory = $true)]
        [string]
        $email
    )

    # https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables
    $command = @"
GIT_COMMITTER_EMAIL='$email';
GIT_AUTHOR_EMAIL='$email';
GIT_COMMITTER_NAME='$name';
GIT_AUTHOR_NAME='$name';
git commit-tree "$@";
"@

    & git filter-branch -f --commit-filter $command head
}

function Edit-GitConfig {
    param([switch] $Global)

    $Path = if ($Global) {
        Join-Path "~" ".gitconfig"
    } else {
        Join-Path "." ".git" "config"
    }

    code $Path
}

function Test-GitClean {
    param($Path = (Get-Location))
    $command = "git -C `"$Path`" status -z"
    # Write-Host $command

    $backupExitCode = $global:LASTEXITCODE
    $statusString = Invoke-Expression $command | Out-String
    $global:LASTEXITCODE = $backupExitCode

    !($statusString)
}

function Test-GitDirty {
    param($Path = (Get-Location))
    !(Test-GitClean -Path $Path)
}
