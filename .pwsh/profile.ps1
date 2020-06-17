Write-Host PWSH $($psversiontable.PSEdition) $($psversiontable.PSVersion)

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

# allow calling scripts without '.\' prefix
$env:path = $env:path + ";."

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
