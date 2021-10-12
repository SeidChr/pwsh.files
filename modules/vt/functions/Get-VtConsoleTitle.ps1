# .SYNOPSIS
# Gets a token which sets the title of the console

param(
    [string] $Title
)

"$([char]0x1b)]2;$Title$([char]0x07)"
