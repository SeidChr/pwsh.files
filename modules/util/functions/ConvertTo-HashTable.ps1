param ( 
    [Parameter(Mandatory)]
    [scriptblock]$Key,

    [Parameter(Mandatory)]
    [scriptblock]$Value 
)

begin {
    $result = @{}
}

process {
    $result.Add((. $Key), (. $Value))
}

end {
    $result
}
