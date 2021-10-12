# load functions
Require  -From ( Join-Path $PSScriptRoot "functions" )

Invoke-WebRequest https://nodejs.org/dist/v15.0.1/node-v15.0.1-win-x64.zip -OutFile "node.zip"
Expand-PartialArchive -Path ".\node.zip" -DestinationPath ".\node" -Like "node-v15.0.1-win-x64/*"