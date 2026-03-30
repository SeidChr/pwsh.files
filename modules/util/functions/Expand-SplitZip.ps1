<#
.SYNOPSIS
    Combines and extracts split .part zip archives.

.DESCRIPTION
    Finds groups of *.zip.XX.part files in a folder, combines each group into a
    single zip archive, and extracts it. The combined zip is removed after successful
    extraction unless -KeepZip is specified.

.PARAMETER Path
    Folder to search for .part files. Defaults to the current directory.

.PARAMETER DestinationPath
    Folder to extract files into. Defaults to the same folder as the .part files.

.PARAMETER KeepZip
    When specified, the combined zip file is kept after extraction.

.EXAMPLE
    .\Expand-SplitZip.ps1

.EXAMPLE
    .\Expand-SplitZip.ps1 -Path "C:\Downloads\export" -DestinationPath "C:\Output" -KeepZip
#>
[CmdletBinding()]
param(
    [string] $Path            = $PWD,
    [string] $DestinationPath = $null,
    [switch] $KeepZip
)

$Path = Resolve-Path $Path

if (-not $DestinationPath) {
    $DestinationPath = $Path
}

# Group part files by their base name (everything before the .XX.part suffix)
$partFiles = Get-ChildItem -Path $Path -Filter "*.part" |
    Where-Object { $_.Name -match '^(.+\..+?)\.\d+\.part$' }

if (-not $partFiles) {
    Write-Warning "No *.XX.part files found in '$Path'."
    return
}

$groups = $partFiles | Group-Object { $_.Name -replace '\.\d+\.part$', '' }

foreach ($group in $groups) {
    $baseName  = $group.Name            # e.g. Export_123.zip
    $combinedPath = Join-Path $Path $baseName
    $parts     = $group.Group | Sort-Object Name

    Write-Host "`nProcessing '$baseName' ($($parts.Count) parts)..."

    # Combine parts
    try {
        $outStream = [System.IO.File]::Open($combinedPath, [System.IO.FileMode]::Create)
        foreach ($part in $parts) {
            Write-Host "  + $($part.Name)"
            $inStream = [System.IO.File]::OpenRead($part.FullName)
            $inStream.CopyTo($outStream)
            $inStream.Close()
        }
        $outStream.Close()
        $sizeMB = [math]::Round((Get-Item $combinedPath).Length / 1MB, 1)
        Write-Host "  Combined: $sizeMB MB"
    } catch {
        Write-Error "Failed to combine parts for '$baseName': $_"
        continue
    }

    # Extract
    try {
        Write-Host "  Extracting to '$DestinationPath'..."
        Expand-Archive -Path $combinedPath -DestinationPath $DestinationPath -Force
        Write-Host "  Extraction complete."
    } catch {
        Write-Error "Failed to extract '$combinedPath': $_"
        continue
    }

    # Cleanup
    if (-not $KeepZip) {
        Remove-Item $combinedPath -Force
        Write-Host "  Removed combined zip."
    }
}

Write-Host "`nDone."
