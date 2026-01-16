param ( 
    [Alias('Key')]
    [scriptblock] $KeySelector,
    [Alias('Value')]
    [scriptblock] $ValueSelector,
    # allows to specify a function which returns an array of size two, which has first key, then selector in it
    [scriptblock] $KeyValueSelector,
    [Parameter(ValueFromPipeline)] $InputObject,
    [switch]$AsObject
)

begin {
    $result = @{}
    if ($KeyValueSelector) {
        $keyValueBlock = [scriptblock]::Create("param(`$_) $KeyValueSelector")
    } else {
        $keyBlock = [scriptblock]::Create("param(`$_) $KeySelector")
        $valueBlock = [scriptblock]::Create("param(`$_) $ValueSelector")
    }
}

end {
    if ($AsObject) {
        [pscustomobject]$result
    } else {
        $result
    }
}

process {
    if ($keyValueBlock) {
        $ko, $vo = . $keyValueBlock $InputObject
    } else {
        $ko = . $KeyBlock $InputObject
        $vo = . $ValueBlock $InputObject
    }

    $result.Add($ko, $vo)
}
