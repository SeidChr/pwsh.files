[OutputType([Result])]
param()

class Result {
    $DirectoryName
    $ProjectName
}

Get-CsProjectFiles
| ForEach-Object { 
    $a = $_.Directory.Name
    $b = $_.Name | Split-Path -LeafBase
    if ($a -ne $b) {
        [Result]@{
            DirectoryName = $a
            ProjectName   = $b
        }
    }
}
