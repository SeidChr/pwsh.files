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
