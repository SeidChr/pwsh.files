param([string]$Path)
if (!(Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path
}
