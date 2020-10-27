param(
    [string] $Path,
    [string] $DestinationPath,
    [string] $like
)

Ensure-Path -Path $DestinationPath
$DestinationPath = Resolve-Path $DestinationPath
$Path = Resolve-Path $Path

Add-Type -AssemblyName System.IO.Compression.FileSystem


$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Path))
try {
    $zip.Entries `
        | Where-Object { $_.FullName -like $like -and $_.Name } `
        | ForEach-Object {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile(
                $_,
                "$DestinationPath\$($_.Name)",
                $true
            )
        }
} finally {
    $zip.Dispose()
}