$ModuleRoot = $PSScriptRoot

$functionsPath = Join-Path $ModuleRoot "functions"
$globalPath = Join-Path $ModuleRoot "global.ps1"

if (Test-Path $globalPath) {
    . $globalPath
}

if (Test-Path $functionsPath) {
    foreach ($filePath in [System.IO.Directory]::EnumerateFiles($functionsPath, "*.ps1")) {
        $functionName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $functionBody = $ExecutionContext.SessionState.Module.NewBoundScriptBlock(
            [scriptblock]::Create([System.IO.File]::ReadAllText($filePath))
        )
        Set-Item -LiteralPath "Function:$functionName" -Value $functionBody
    }
}
