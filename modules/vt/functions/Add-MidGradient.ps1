# .SYNOPSIS
# Sets a color code on a text. The color is a mix of
# StartColor and MidColor or MidColor and EndColor,
# according to where between Min, Mid and Max the
# current Value is

param(
    [Parameter(Mandatory)]
    [string] $StartColor,

    [Parameter(Mandatory)]
    [string] $MidColor,

    [Parameter(Mandatory)]
    [string] $EndColor,

    [Parameter(Mandatory)]
    [double] $Min,

    [Parameter(Mandatory)]
    [double] $Mid,

    [Parameter(Mandatory)]
    [double] $Max,

    [Parameter(Mandatory)]
    [double] $Value,

    [Parameter(Mandatory, ValueFromPipeline)]
    [string] $Text
)

if ($Value -lt $Mid) {
    $Text | Add-Gradient $StartColor $MidColor $Min $Mid $Value
} else {
    $Text | Add-Gradient $MidColor $EndColor $Mid $Max $Value
}
