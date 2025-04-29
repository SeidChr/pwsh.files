param ( 
    [scriptblock] $Key,
    [scriptblock] $Value,
    [Parameter(ValueFromPipeline)] $InputObject
    [switch]$AsObject
)

begin {
    $result = @{}
    $keyBlock = [scriptblock]::Create("param(`$_) $Key")
    $valueBlock = [scriptblock]::Create("param(`$_) $Value")
}

end {
    if ($AsObject) {
        [pscustomobject]$result
    } else {
        $result
    }
}

process { 
    $ko = . $KeyBlock $InputObject
    $vo = . $ValueBlock $InputObject
    $result.Add($ko, $vo)
}
