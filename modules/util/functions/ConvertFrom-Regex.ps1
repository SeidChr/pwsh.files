param(
    [Parameter(ValueFromPipeline)]
    $InputObject,

    [Parameter(Mandatory, Position = 0)]
    $Regex
)
process {
    [regex]::Matches($_, $Regex) | ForEach-ObjectFast {
        $result = @{}
        $_.Groups | ForEach-ObjectFast {
            $result.Add($_.Name, $_.Value)
        }
        $result
    }
}