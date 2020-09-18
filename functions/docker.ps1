function Test-DockerAvailable {
    $null = & docker version *>&1
    $LASTEXITCODE -eq 0
}

function Start-Docker4Windows {
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
    } else {
        Write-Host "Docker 4 Windows is already running."
    }
}

function Start-Docker {
    if ($IsWindows) {
        Start-Docker4Windows
    }
}

function Get-DockerShell {
    param(
        $image = "debian",
        [Alias("shell")]
        $entrypoint,
        [Alias("mappedFolderPath")]
        $mapFrom,
        $mapTo = "project"
    )

    Start-Docker

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