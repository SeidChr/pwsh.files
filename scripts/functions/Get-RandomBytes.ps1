param([long]$Count)
[byte[]](Get-Random -Count $Count -Maximum 256)