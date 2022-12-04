cd ~\Desktop\
$param = "CreationTime"
#$destinations = "OneDrive", "Synology"
ls | select *, @{ L = "Date"; E = { $_.$param.Date } } | Group-Object Date | % {
    $date = $_.Group | select -First 1 -ExpandProperty $param
    $dateShortString = $date.ToString("yyyyMMdd")
    
    Write-Host "Date: $date" -ForegroundColor Blue
    Write-Host "Files:" -ForegroundColor Blue
    $_.Group | % Name | % {
        Write-Host ">> $_" -ForegroundColor Yellow
    }
    Select-Option -Caption "Storage Destination" -Message "Where to put this Stuff?" -Choices "&OneDrive", "&Synology" -Default 1
    Write-Host
}