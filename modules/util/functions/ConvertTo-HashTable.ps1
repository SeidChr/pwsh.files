param ( 
    [scriptblock] $Key,
    [scriptblock] $Value,
    [Parameter(ValueFromPipeline)] $InputObject
)

begin {
    $result = @{}
    $keyBlock = [scriptblock]::Create("param(`$_) $Key")
    $valueBlock = [scriptblock]::Create("param(`$_) $Value")
}

end {
    $result
}

process { 
    $ko = . $KeyBlock $InputObject
    $vo = . $ValueBlock $InputObject
    $result.Add($ko, $vo)
}
