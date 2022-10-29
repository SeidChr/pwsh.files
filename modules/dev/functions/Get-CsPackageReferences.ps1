[OutputType([Result])]
param()

class Result {
    $Name
    $Version
}

Get-CsProjectFiles
| Get-Content -Raw 
| ForEach-Object { 
    $xml = [xml]$_
    $xml.Project.ItemGroup.PackageReference
} 
| Group-Object -Property Include 
| ForEach-Object {
    [Result]@{
        Name    = $_.Name
        Version = $_.Group.Version | Sort-Object -Unique
    }
}