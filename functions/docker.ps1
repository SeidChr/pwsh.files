function Test-DockerAvailable {
    $null = & docker version *>&1
    $LASTEXITCODE -eq 0
}

function Start-Docker4Windows {
    param([switch] $nomsg)
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
}

function Start-Docker {
    if ($IsWindows) {
        Start-Docker4Windows @args
    }
}

function Get-DockerShell {
    param(
        [Parameter(Position = 0)]
        $image = "debian",

        [Parameter(Position = 1)]
        [Alias("shell")]
        $entrypoint,

        [Alias("mappedFolderPath")]
        $mapFrom,

        $mapTo = "project"
    )

    Start-Docker -nomsg

    $entrypointArgument = "";
    $mappingArgument = ""

    $image = switch ($image) {
        ".netsdk" { "mcr.microsoft.com/dotnet/core/sdk"; break }
        ".netasp" { "mcr.microsoft.com/dotnet/core/aspnet"; break }
        { $_ -in ".net", ".netrt" } { "mcr.microsoft.com/dotnet/core/runtime"; break }
        { $_ -in ".netdeps", ".netrtdeps" } { "mcr.microsoft.com/dotnet/core/runtime-deps"; break }
        default { $image }
    }

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