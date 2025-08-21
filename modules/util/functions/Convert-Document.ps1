param(
    $InputDocumentPath,
    $PanDocVersion = 'pandoc/latex:3.4',
    $OutputFormat,
    [switch] $ForceOverwrite
)

# Wait for Docker to be ready
while (-not (Test-DockerAvailable)) {
    Write-Host "Docker not started. Waiting."
    Start-Sleep -Seconds 10
    Write-Host "Retrying..."
}

# Create a temporary folder for processing
$dataFolder = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
Write-Host "Using temp folder $($dataFolder)."
New-Item -ItemType Directory -Path $dataFolder > $null

# Copy referenced input document into the temporary folder
$inputFileName = Split-Path -Path $InputDocumentPath -Leaf
Copy-Item -Path $InputDocumentPath -Destination $dataFolder
$inputTempFilePath = Join-Path $dataFolder $inputFileName

# Define output file name based on input and specified format
$outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($inputFileName) + "." + $OutputFormat
$outputFilePath = Join-Path -Path $dataFolder -ChildPath $outputFileName

# Run the Docker command to execute Pandoc
Write-Host "Running Pandoc Docker container..."
docker run --rm --volume "$($dataFolder):/data" $PanDocVersion "/data/$inputFileName" "--extract-media=/data/media" -o "/data/$outputFileName" 

# Check if the output file is created
if (Test-Path -Path $outputFilePath) {
    Write-Host "Converted document is saved in the temporary folder: $outputFilePath"
} else {
    Write-Host "Error: Failed to convert the document using Pandoc Docker."
}

# Define the target folder path using input document name and output format
$inputDocumentBaseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFileName)
$targetFolderName = "${inputDocumentBaseName}_${OutputFormat}_Output"
$targetFolderPath = Join-Path -Path (Get-Location) -ChildPath $targetFolderName
if (Test-Path -Path $targetFolderPath) {
    if ($ForceOverwrite) {
        Write-Host "Target folder '$targetFolderPath' already exists. Overwriting as requested with -ForceOverwrite switch."
        Remove-Item -Path $targetFolderPath -Recurse -Force
    } else {
        throw "Error: Target folder '$targetFolderPath' already exists. Use the -ForceOverwrite switch to overwrite it."
    }
}

# Wait for Docker to be ready
while (-not (Test-DockerAvailable)) {
    Write-Host "Docker not started. Waiting."
    Start-Sleep -Seconds 10
    Write-Host "Retrying..."
}

# Create a temporary folder for processing
$dataFolder = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
Write-Host "Using temp folder $($dataFolder)."
New-Item -ItemType Directory -Path $dataFolder > $null

# Copy referenced input document into the temporary folder
Copy-Item -Path $InputDocumentPath -Destination $dataFolder
$inputTempFilePath = Join-Path $dataFolder $inputFileName

# Define output file name based on input and specified format
$outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($inputFileName) + "." + $OutputFormat
$outputFilePath = Join-Path -Path $dataFolder -ChildPath $outputFileName

# Run the Docker command to execute Pandoc
Write-Host "Running Pandoc Docker container..."
docker run --rm --volume "$($dataFolder):/data" -w "/data" $PanDocVersion "$inputFileName" '--extract-media=.' -o "$outputFileName"

# Check if the output file is created
if (Test-Path -Path $outputFilePath) {
    Write-Host "Converted document is saved in the temporary folder: $outputFilePath"
} else {
    Write-Host "Error: Failed to convert the document using Pandoc Docker."
}

# Move the temporary folder to the target folder
Move-Item -Path $dataFolder -Destination $targetFolderPath
Write-Host "Moved output to: $targetFolderPath" 