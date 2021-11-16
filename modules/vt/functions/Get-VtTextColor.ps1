# .SYNOPSIS
# Gets a vt token which sets a certain color on the text.
# When the color is a hex-string, it will be converted to
# 3 integers, which can also be passed directly

param(
    $Color,
    [switch] $Bg
)

if ($Color) {
    if ($Color -is [string]) {
        $Color = $Color | ConvertTo-Rgb
    }

    $code = $Color
        | ForEach-Object { [string]$_ }
        | Join-String -Separator ";"

    "$script:escapeToken[$($Bg ? "48" : "38");2;$($code)m"
} else {
    # reset fg or bg to default
    "$script:escapeToken[$($Bg ? "49" : "39")m"
}
