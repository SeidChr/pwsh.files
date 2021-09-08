$script:escapeToken = [char]27

# .SYNOPSIS
# Converts any Hex color-string into series of 3 integer
# color codes for r g and b
function ConvertTo-Rgb {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $HexColor
    )
    $startAt = 0;
    $width = 2
    switch ($HexColor.Length) {
        # 06C
        3 { $width = 1 }
        # #06C
        4 { $startAt = 1; $width = 1 }
        # 0066CC
        6 { $startAt = 0 }
        # #0066CC
        7 { $startAt = 1 }
        default { thow }
    }

    0..2 | ForEach-Object {
        $offset = $startAt + $_ * $width
        [int]("0x" + ($HexColor.Substring($offset, $width) * (3 - $width)))
    }
}

# .SYNOPSIS
# Gets a vt token which clears all active modifiers
function Get-VtClear {
    "$script:escapeToken[0m" 
}

# .SYNOPSIS
# Gets a vt token which sets a certain color on the text.
# When the color is a hex-string, it will be converted to
# 3 integers, which can also be passed directly
function Get-VtTextColor {
    param(
        $Color,
        [switch] $Bg
    )

    if ($Color) {
        if ($Color -is [string]) {
            $Color = $Color | ConvertTo-Rgb
        }

        $code = $Color `
            | ForEach-Object { [string]$_ } `
            | Join-String -Separator ";"

        "$script:escapeToken[$($Bg ? "48" : "38");2;$($code)m"
    } else {
        # reset fg or bg to default
        "$script:escapeToken[$($Bg ? "49" : "39")m"
    }
}

# .SYNOPSIS
# Gets a token which sets the title of the console
function Get-VtConsoleTitle {
    param([string] $Title)
    "$([char]0x1b)]2;$Title$([char]0x07)"
}

# .SYNOPSIS
# Adds tokens to a text which sets foreground and
# background color, and clears it afterwards
function Add-Color {
    param(
        [Alias("Fg", "Color")]
        $FgColor,

        [Alias("Bg")]
        $BgColor,

        [Parameter(ValueFromPipeline, Mandatory)]
        [string] $Text
    )

    # empty color will reset the specific vt settings
    $FgPrefix = Get-VtTextColor -Color $FgColor
    $BgPrefix = Get-VtTextColor -Color $BgColor -Bg

    "$($FgPrefix + $BgPrefix)$Text$(Get-VtClear)"
}

# .SYNOPSIS
# Adds underline-tokens arround a text
function Add-Underline {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string] $Text
    )

    "$script:escapeToken[4m$Text$script:escapeToken[24m"
}

# .SYNOPSIS
# Adds color codes to a text, which grades a color
# between min and max according the current value
function Add-Gradient {
    param(
        [Parameter(Mandatory)]
        [string] $Start,

        [Parameter(Mandatory)]
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
}

# .SYNOPSIS
# Gets a perventage of where the value is
# positioned between min and max
function Get-Progress {
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
        { $_ -lt $Min } { $Min }
        { $_ -gt $Max } { $Max }
        default { $Value }
    }

    $Value -= $Min
    $Max -= $Min
    $Value / $Max
}

# .SYNOPSIS
# Sets a color code on a text. The color is a mix of
# StartColor and MidColor or MidColor and EndColor,
# according to where between Min, Mid and Max the
# current Value is
function Add-MidGradient {
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
}
