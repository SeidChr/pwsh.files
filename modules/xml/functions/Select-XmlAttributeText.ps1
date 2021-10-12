<#
    .SYNOPSIS
    Selects an Attribute and returns its String-Value
#>

[CmdletBinding()]
[OutputType([string])]

param(
    [Parameter(ValueFromPipeline=$true)]
    [xml] $Xml, 
    [Parameter(Position = 0)]
    [string] $AttributeXPath
)

$Xml | Select-Xml $AttributeXPath `
    | Select-Object -ExpandProperty Node `
    | Select-Object -ExpandProperty "#text"