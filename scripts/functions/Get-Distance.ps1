param(
    [double]$LatOrigin, 
    [double]$lonOrigin, 
    [double]$LatDestination,
    [double]$LonDestination
)

$radius = 6371  # km

# https://stackoverflow.com/a/19677131/1280354
$rad = [Math]::PI / 180

$LatOrigin *= $rad
$LatDestination *= $rad

$LonOrigin *= $rad
$LonDestination *= $rad

$dlat = $LatDestination - $LatOrigin
$dlon = $LonDestination - $lonOrigin

$a = (
    [Math]::sin($dlat / 2) * [Math]::sin($dlat / 2) +
    [Math]::Sin($dlon / 2) * [Math]::Sin($dlon / 2) * [Math]::Cos($LatOrigin) * [Math]::Cos($LatDestination)
)

$c = 2 * [Math]::Atan2([Math]::sqrt($a), [Math]::sqrt(1 - $a))
$radius * $c