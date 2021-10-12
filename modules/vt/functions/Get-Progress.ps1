# .SYNOPSIS
# Gets a perventage of where the value is
# positioned between min and max

param(
    [Parameter(Mandatory)]
    [double] $Min,

    [Parameter(Mandatory)]
    [double] $Max,

    [Parameter(Mandatory, ValueFromPipeline)]
    [double] $Value
)

if ($Min -gt $Max) {
    $tmp = $Min
    $Min = $Max
    $Max = $tmp
}

$value = switch ($Value) {
    { $_ -lt $Min } {
        $Min 
    }
    { $_ -gt $Max } {
        $Max 
    }
    default {
        $Value 
    }
}

$Value -= $Min
$Max -= $Min
$Value / $Max
