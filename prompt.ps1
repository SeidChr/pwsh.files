function prompt {
    param($tag = "")
    $homePath = (Resolve-Path ~).ToString()
    $locationPath = (Get-Location).ToString()
    $nestedPrefix = ">" * $global:shellNestingLevel

    $status = if (Test-Path function:PROMPTSTATUS) { PROMPTSTATUS }

    $exitCodePrefix = if ($LASTEXITCODE) { [string]$LASTEXITCODE }

    Write-Host
    Write-Host ($exitCodePrefix + $nestedPrefix + $tag + "> ") -NoNewline -ForegroundColor Red

    if ($homePath -ieq $locationPath) {
        if ($global:sharing) {
            Write-Host "~" -ForegroundColor Green
        } else {
            Write-Host "~ " -NoNewline -ForegroundColor Green
            Write-Host "($homePath)" -ForegroundColor DarkGray
        }
    }
    else {
        if ((-not $IsWindows) -and ($locationPath -eq "/")) {
            $leaf = "/"
            $parent = ""
        }
        else {
            $leaf = Split-Path -Leaf $locationPath
            $parent = Split-Path -Parent $locationPath
        }

        if ($parent) {
            $parentShort = $parent.Replace($homePath, "~").TrimEnd([System.IO.Path]::DirectorySeparatorChar)
            Write-Host $parentShort -NoNewline -ForegroundColor DarkCyan
            Write-Host "$([System.IO.Path]::DirectorySeparatorChar)" -NoNewline -ForegroundColor Red
        }

        Write-Host $leaf -ForegroundColor Green
    }

    if ($status) {
        Write-Host $status -NoNewline -ForegroundColor Red
    }

    Write-Host "$" -NoNewline -ForegroundColor DarkGray
    return " "
}
