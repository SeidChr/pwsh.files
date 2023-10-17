param(
    [Parameter(Position = 0)]
    $Image = "debian",

    [Parameter(Position = 1)]
    [Alias("shell")]
    $Entrypoint,

    [Alias("p")]
    $Expose,

    [Alias("mappedFolderPath")]
    $MapFrom,

    $MapTo = "project",

    [Alias("w")]
    [Alias("wd")]
    [Alias("location")]
    $WorkingDirectory,

    [Alias("u")]
    $User
)

Start-Docker -nomsg

$entrypointArgument = ""
$mappingArgument = ""
$workingDirectoryArgument = ""

$Image = switch ($Image) {
    ".netsdk" { "mcr.microsoft.com/dotnet/sdk"; break }
    ".netasp" { "mcr.microsoft.com/dotnet/core/aspnet"; break }
    { $_ -in ".net", ".netrt" } { "mcr.microsoft.com/dotnet/runtime"; break }
    { $_ -in ".netdeps", ".netrtdeps" } { "mcr.microsoft.com/dotnet/runtime-deps"; break }
    { $_ -in ".ps", ".pwsh", ".powershell" } { "mcr.microsoft.com/powershell"; break }
    default { $Image }
}

if ($Entrypoint) {
    $entrypointArgument = "--entrypoint $Entrypoint";
}

if ($MapTo -and -not ($MapTo.StartsWith("/"))) {
    $MapTo = "/" + $MapTo;
}

if ($WorkingDirectory -and -not ($WorkingDirectory.StartsWith("/"))) {
    $WorkingDirectory = "/" + $WorkingDirectory;
}

if ($MapFrom) {
    if (!$WorkingDirectory -and $MapTo) {
        $WorkingDirectory = $MapTo
    }

    $mappingArgument = "-v `"$(Resolve-Path $MapFrom):$MapTo`""
}

if ($WorkingDirectory) {
    $workingDirectoryArgument = "-w `"$WorkingDirectory`""
}

if ($User) {
    $userArgument = "--user `"$User`""
}

$exposeArgument = ""
if ($Expose) {
    $exposeArgument = "-p $Expose"
}

$cmd = "docker run -it --rm $mappingArgument $workingDirectoryArgument $entrypointArgument $userArgument $exposeArgument $Image";
Write-Host "Command: " $cmd

Invoke-Expression $cmd