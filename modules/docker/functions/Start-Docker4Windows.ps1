param(
    [switch] $nomsg
)

if (-not $IsWindows) {
    return
}

if (-not (Test-DockerAvailable)) {
    Write-Host "Starting Docker 4 Windows." -NoNewline
    Start-Process (Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe")
    while (-not (Test-DockerAvailable)) {
        Start-Sleep -Seconds 10
        Write-Host "." -NoNewline
    }

    Write-Host "done."
} elseif (-not $nomsg) {
    Write-Host "Docker 4 Windows is already running. $nomsg"
}
