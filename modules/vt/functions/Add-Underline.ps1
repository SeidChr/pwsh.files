# .SYNOPSIS
# Adds underline-tokens arround a text

param(
    [Parameter(ValueFromPipeline, Mandatory)]
    [string] $Text
)

"$script:escapeToken[4m$Text$script:escapeToken[24m"
