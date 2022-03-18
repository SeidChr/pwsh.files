param(
    [Parameter(Position = 0)]
    $image = "debian",

    [Parameter(Position = 1)]
    [Alias("shell")]
    $entrypoint,

    [Alias("mappedFolderPath")]
    $mapFrom,

    $mapTo = "project",

    [Alias("w")]
    [Alias("wd")]
    [Alias("location")]
    $workingDirectory
)

Start-Docker -nomsg

$entrypointArgument = ""
$mappingArgument = ""
$workingDirectoryArgument = ""

$image = switch ($image) {
    ".netsdk" { "mcr.microsoft.com/dotnet/sdk"; break }
    ".netasp" { "mcr.microsoft.com/dotnet/core/aspnet"; break }
    { $_ -in ".net", ".netrt" } { "mcr.microsoft.com/dotnet/runtime"; break }
    { $_ -in ".netdeps", ".netrtdeps" } { "mcr.microsoft.com/dotnet/runtime-deps"; break }
    default { $image }
}

if ($entrypoint) {
    $entrypointArgument = "--entrypoint $entrypoint";
}

if ($mapTo -and -not ($mapTo.StartsWith("/"))) {
    $mapTo = "/" + $mapTo;
}

if ($workingDirectory -and -not ($workingDirectory.StartsWith("/"))) {
    $workingDirectory = "/" + $workingDirectory;
}

if ($mapFrom) {
    if (!$workingDirectory -and $mapTo) {
        $workingDirectory = $mapTo
    }

    $mappingArgument = "-v `"$(Resolve-Path $mapFrom):$mapTo`""
}

if ($workingDirectory) {
    $workingDirectoryArgument = "-w `"$workingDirectory`""
}

$cmd = "docker run -it --rm $mappingArgument $workingDirectoryArgument $entrypointArgument $image";
Write-Host "Command: " $cmd

Invoke-Expression $cmd