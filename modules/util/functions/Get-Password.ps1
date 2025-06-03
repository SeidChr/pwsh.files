param(
    [int]$Lenght = 10,
    [int]$MinSpecial = 1,
    [int]$MinUpper = 1,
    [int]$MinLower = 1,
    [int]$MinDigits = 1
)

$Chars = @{
    Special = '!@#$%&_-*~?.|+'
    Upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    Lower   = 'abcdefghijkmnopqrstuvwxyz'
    Digit   = '23456789'
}

$minSize = $MinSpecial + $MinUpper + $MinLower + $MinDigits

$padding = $Lenght - $minSize

if ($padding -lt 0) {
    throw 'Required length leaves not enough space for minimum char requirements'
}

function RandomChars {
    param([int]$Count, [Parameter(ValueFromPipeline)]$String)
    if ($Count -le 0) {
        return
    }

    $charArray = $String.ToCharArray()
    $resultChars = for ($i = 0; $i -lt $Count; $i++) {
        $charArray | Get-Random 
    }

    [string]::Concat($resultChars)
}

function FillRandomPadding {
    param([int]$TargetLength, [Parameter(ValueFromPipeline)]$String)
    
    $pad = $TargetLength - $String.Length

    if ($pad -le 0) {
        return $String
    }

    $String + ($String | RandomChars -Count $pad)
}

$maxCharsetLength = $Chars.Values.Length | Measure-Object -Maximum | ForEach-Object Maximum

$specialChars = $Chars.Special | FillRandomPadding $maxCharsetLength
$upperChars = $Chars.Upper | FillRandomPadding $maxCharsetLength
$lowerChars = $Chars.Lower | FillRandomPadding $maxCharsetLength
$digitChars = $Chars.Digit | FillRandomPadding $maxCharsetLength

$specialPart = $specialChars | RandomChars $MinSpecial
$upperPart = $upperChars | RandomChars $MinUpper
$lowerPart = $lowerChars | RandomChars $MinLower
$digitPart = $digitChars | RandomChars $MinDigit

$paddingPart = ($specialChars + $upperChars + $lowerChars + $digitChars) | RandomChars $padding

[string]::Concat((($specialPart + $upperPart + $lowerPart + $digitPart + $paddingPart).ToCharArray() | Get-Random -Shuffle))