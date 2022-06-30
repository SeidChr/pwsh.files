# .SYNOPSIS
function Get-Crypto {
    param(
        #fsym: symbol of INTEREST
        [Alias('fsym')]
        $SymbolOfInterest = "BTC",
        #tsyms: symbols to convert INTO; comma separated
        [Alias('tsyms')]
        $ConversionSymbols = "EUR,USD"
    )

    Invoke-RestMethod -Uri "https://min-api.cryptocompare.com/data/price?fsym=$SymbolOfInterest&tsyms=$ConversionSymbols"
}