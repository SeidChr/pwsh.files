function prompt {
    $homePath = (Resolve-Path ~).ToString()
    $locationPath = (Get-Location).ToString()

    #Write-Host $homePath.GetType() $locationPath.GetType() ($homePath -ieq $locationPath)

    #(Get-Date -UFormat '%y/%m/%d %R').Tostring()
        
    # wont change vscode name
    #$Host.UI.RawUI.WindowTitle = $leaf

    # empty line before each prompt
    Write-Host
    Write-Host "> " -NoNewline -ForegroundColor Red

    if ($homePath -ieq $locationPath) {
        Write-Host "~ " -NoNewline -ForegroundColor Green
        Write-Host "($homePath)" -ForegroundColor DarkGray
    } else {
        $leaf = Split-Path -Leaf $locationPath
        $parent = Split-Path -Parent $locationPath

        $parentShort = $parent.Replace($homePath, "~")

        Write-Host $parentShort -NoNewline -ForegroundColor Blue
        Write-Host "$([System.IO.Path]::DirectorySeparatorChar)" -NoNewline -ForegroundColor Red
        Write-Host $leaf -ForegroundColor Green
    }

    Write-Host "$" -NoNewline -ForegroundColor DarkGray
    return " "
}
