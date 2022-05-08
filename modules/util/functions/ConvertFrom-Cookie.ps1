# .SYNOPSIS
# Converts a classical cookie string into an hashtable, where every cookie has a key.
param(
    [Parameter(ValueFromPipeline)]
    $InputObject,

    # Delimiter of key-value-pairs
    $KvpDelimiter = ';',

    # Delimiter of key and value
    $KvDelimiter = '='
)

process {
    $result = @{}
    $_.split($KvpDelimiter) | ForEach-ObjectFast {
        $kvp = $_.trim().split($KvDelimiter)
        $result.add($kvp[0], $kvp[1])
    }
    return $result
}