# .SYNOPSIS
# Adds color codes to a text, which grades a color
# between min and max according the current value

param(
    [Parameter(Mandatory)]
    [Alias("StartColor")]
    [string] $Start,

    [Parameter(Mandatory)]
    [Alias("EndColor")]
    [string] $End,

    [Parameter(Mandatory)]
    [double] $Min,

    [Parameter(Mandatory)]
    [double] $Max,

    [Parameter(Mandatory)]
    [double] $Value,

    [Parameter(Mandatory, ValueFromPipeline)]
    [string] $Text
)

$progress = $Value | Get-Progress $Min $Max

$startSet = $Start | ConvertTo-Rgb
$endSet = $End | ConvertTo-Rgb

# $startSet
# $endSet
$code = 0..2 | ForEach-Object {
    $a = $startSet[$_]
    $b = $endSet[$_]
    [int]((($b - $a) * $Progress) + $a)
}

$Text | Add-Color $code
