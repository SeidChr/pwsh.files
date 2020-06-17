function prompt {
    $homePath = Resolve-Path ~
    $locationPath = Get-Location;
    $leaf = Split-Path -Leaf $locationPath
    $parent = Split-Path -Parent $locationPath

    #(Get-Date -UFormat '%y/%m/%d %R').Tostring()
    # wont change vscode name
    $Host.UI.RawUI.WindowTitle = $leaf

    #$parent = $direcotry.Parent;
    #$parentFull = $parent.FullName
    $parentShort = $parent.Replace($homePath, "~")

    Write-Host
    Write-Host "> " -NoNewline -ForegroundColor Red
    Write-Host $parentShort -NoNewline -ForegroundColor Blue
    Write-Host "$([System.IO.Path]::DirectorySeparatorChar)" -NoNewline -ForegroundColor Red
    Write-Host ($leaf + " ") -ForegroundColor Green

    Write-Host "$" -NoNewline -ForegroundColor DarkGray
    return     " "
}
