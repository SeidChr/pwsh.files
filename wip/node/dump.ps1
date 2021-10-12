$projectRoot = Get-Location
$nodeVersion = "v14.15.1"
$nodeFileBase = "node-$nodeVersion-win-x64"
$nodeFolder = Join-Path $projectRoot "node"
$nodeUrl = "https://nodejs.org/dist/$nodeVersion/$nodeFileBase.zip"
$nodePath = Join-Path $nodeFolder $nodeFileBase

function Install-LocalNode {
    param(
        $url,
        $destinationPath
    )
    # create temp with zip extension (or Expand will complain)
    $tmp = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'zip' } -PassThru
    
    #download
    Invoke-WebRequest -OutFile $tmp $url
    
    Remove-Item -Recurse $destinationPath

    #exract to same folder 
    $tmp | Expand-Archive -DestinationPath $destinationPath -Force

    # remove temporary file
    $tmp | Remove-Item
}

function BootstrapNode {
    Install-LocalNode -url $nodeUrl -destinationPath $nodeFolder
}