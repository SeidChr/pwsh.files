# .SYNOPSIS
# Adds tokens to a text which sets foreground and
# background color, and clears it afterwards

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
