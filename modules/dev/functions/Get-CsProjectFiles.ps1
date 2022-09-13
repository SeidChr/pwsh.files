Get-ChildItem -Recurse -Directory 
| Where-Object { !$_.FullName.Contains("node_modules") } 
| ForEach-Object { Get-ChildItem -Path $_.FullName *.csproj -File } 