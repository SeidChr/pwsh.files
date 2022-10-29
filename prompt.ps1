function prompt {
    param(
        $tag = ""
    )

    $darkCyan = Get-VtTextColor "#11A8CD"
    $red      = Get-VtTextColor "#F14C4C"
    $green    = Get-VtTextColor "#23D18B"
    $darkGray = Get-VtTextColor "#666666"
    $bright   = Get-VtTextColor "#CCCCCC"
    $clear    = Get-VtClear

    $homePath     = (Resolve-Path ~).ToString()
    $locationPath = (Get-Location).ToString()
    $nestedPrefix = ">" * $global:shellNestingLevel

    $exitCodePrefix = if ($LASTEXITCODE) { [string]$LASTEXITCODE }

    $prefixPart = "$red$exitCodePrefix$nestedPrefix$tag>$clear "
    $statusPart = if (Test-Path function:PROMPTSTATUS) { "$red$(PROMPTSTATUS)$clear" }
    $promptPart = "$darkGray`$$bright>$clear " # cursor comes here

    $locationPart = ""
    if ($homePath -ieq $locationPath) {
        $homePart = "$green~$clear"
        if ($global:sharing) {
            $locationPart = $homePart
        } else {
            $locationPart = "$homePart $darkGray($homePath)$clear"
        }
    } else {
        $parentPart = ""

        if ((-not $IsWindows) -and ($locationPath -eq "/")) {
            $leaf = "/"
            $parent = ""
        } else {
            $leaf = Split-Path -Leaf $locationPath
            $parent = Split-Path -Parent $locationPath
        }

        if ($parent) {
            $dirSeparator = [System.IO.Path]::DirectorySeparatorChar
            $parentShort = $parent.Replace($homePath, "~").TrimEnd($dirSeparator)
            $parentPart = "$darkCyan$parentShort$red$dirSeparator$clear"
        }

        $locationPart = "$parentPart$green$leaf$clear"
    }

    return @"

$prefixPart$locationPart
$statusPart$promptPart
"@
}
