param([int] $Count = 5)

# https://github.com/fcgooner/Random-Game-Picker
# https://github.com/RamblingCookieMonster/PSSQLite

$root = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$localModulesPath = Join-Path $root modules
$psSqLitePath = Join-Path $localModulesPath 'PSSQLite'

if ( -not (Test-Path $psSqLitePath) ) {
    Save-Module -Name PSSQLite -Path modules -Force -ErrorAction Stop
}

$env:PSModulePath = "$localModulesPath;$env:PSModulePath"

$database = "C:\ProgramData\GOG.com\Galaxy\storage\galaxy-2.0.db"

$query = @"
    SELECT 
        GamePieces.value 
    FROM 
        ProductPurchaseDates JOIN GamePieces
    ON 
        ProductPurchaseDates.gameReleaseKey = GamePieces.releaseKey
    WHERE
        GamePieces.gamePieceTypeId = 1400
    ORDER BY RANDOM()
    LIMIT $Count
"@

Invoke-SqliteQuery -Database $database -Query $query 
| ForEach-Object { $_.value | ConvertFrom-Json | ForEach-Object title }