Get-ChildItem -Recurse -Directory 
| Where-Object { !$_.FullName.Contains("node_modules") } 
| ForEach-Object { Get-ChildItem -Path $_.FullName *.csproj -File } 
| Get-Content -Raw 
| ForEach-Object { 
    $xml = [xml]$_
    $xml.Project.ItemGroup.PackageReference
} 
| Group-Object -Property Include 
| ForEach-Object {
    [Pscustomobject]@{
        Name    = $_.Name
        Version = $_.Group.Version | Sort-Object -Unique
    }
}