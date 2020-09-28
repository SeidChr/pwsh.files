function prompt {
    param($tag = "")
    $homePath = (Resolve-Path ~).ToString()
    $locationPath = (Get-Location).ToString()
    $nestedPrefix = ">" * $global:shellNestingLevel

    Write-Host
    Write-Host ($nestedPrefix + $tag + "> ") -NoNewline -ForegroundColor Red

    if ($homePath -ieq $locationPath) {
        Write-Host "~ " -NoNewline -ForegroundColor Green
        Write-Host "($homePath)" -ForegroundColor DarkGray
    } else {
        $leaf = Split-Path -Leaf $locationPath
        $parent = Split-Path -Parent $locationPath

        if ($parent) {
            $parentShort = $parent.Replace($homePath, "~").TrimEnd([System.IO.Path]::DirectorySeparatorChar)

            Write-Host $parentShort -NoNewline -ForegroundColor Blue
            Write-Host "$([System.IO.Path]::DirectorySeparatorChar)" -NoNewline -ForegroundColor Red
        }

        Write-Host $leaf -ForegroundColor Green
    }

    Write-Host "$" -NoNewline -ForegroundColor DarkGray
    return " "
}
