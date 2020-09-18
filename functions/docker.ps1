function Get-DockerShell {
    param(
        $image = "debian",
        [Alias("shell")]
        $entrypoint,
        [Alias("mappedFolderPath")]
        $mapFrom,
        $mapTo = "project",
        [switch]
        $start = $false
    )

    if ($start -and $IsWindows) {
        $checkDocker4WinStopped = { 
            $null = & docker version *>&1
            -not $LASTEXITCODE -eq 0
        }

        if (& $checkDocker4WinStopped) {
            Write-Host "Starting Docker 4 Windows" -NoNewline
            Start-Process (Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe")
            while (& $checkDocker4WinStopped) {
                Write-Host "." -NoNewline
                Start-Sleep -Seconds 10
            }

            Write-Host "done."
        } else {
            Write-Host "Docker 4 Windows is already running."
        }
    }

    $entrypointArgument = "";
    $mappingArgument = ""

    if ($entrypoint) {
        $entrypointArgument = "--entrypoint $entrypoint";
    }

    if ($mapFrom) {
        $mappingArgument = "-v `"$(Resolve-Path $mapFrom):/$mapTo`""
    }

    $cmd = "docker run -it --rm $mappingArgument $entrypointArgument $image";
    Write-Host "Command: " $cmd

    Invoke-Expression $cmd
}