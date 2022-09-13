Get-CsProjectFiles
| ForEach-Object { 
    $a = $_.Directory.Name
    $b = $_.Name | Split-Path -LeafBase
    if ($a -ne $b) {
        [pscustomobject]@{
            Directory = $a
            Name      = $b
            # Match     = $a -eq $b
        }
    }
}
# | Where-Object Match -EQ $false
# | Select-Object Directory, Name