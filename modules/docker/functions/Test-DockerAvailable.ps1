$res = & docker version *>&1 | Out-String
if ($res -like "*error during connect*") {
    return $false 
}

$LASTEXITCODE -eq 0