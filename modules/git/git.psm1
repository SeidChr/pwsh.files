$ModuleRoot = $PSScriptRoot

$functionsPath = Join-Path $ModuleRoot "functions"
$globalPath = Join-Path $ModuleRoot "global.ps1"

if (Test-Path $globalPath) {
    . $globalPath
}

if (Test-Path $functionsPath) {
    Get-ChildItem $functionsPath -Filter "*.ps1" | ForEach-Object {
        $name = $(Split-Path -LeafBase $_)
        . Invoke-Expression "function $name { $(Get-Content $_ -Raw) }";
        Export-ModuleMember -Function $name
    }
}