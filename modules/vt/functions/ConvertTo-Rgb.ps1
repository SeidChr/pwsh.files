# .SYNOPSIS
# Converts any Hex color-string into series of 3 integer
# color codes for r g and b

param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string] $HexColor
)

$startAt = 0;
$width = 2

switch ($HexColor.Length) {
    # 06C
    3 {
        $width = 1
    }
    # #06C
    4 {
        $startAt = 1; $width = 1
    }
    # 0066CC
    6 {
        $startAt = 0
    }
    # #0066CC
    7 {
        $startAt = 1
    }
    default {
        thow
    }
}

0..2 | ForEach-Object {
    $offset = $startAt + $_ * $width
    [int]("0x" + ($HexColor.Substring($offset, $width) * (3 - $width)))
}
