param(
    [Alias('Property')]
    [string] $SourcePropertyName = 'Properties'
)

begin {
    $PropertyKeys = [System.Collections.Generic.HashSet[string]]::new()
    $collection = [System.Collections.Generic.List[System.Object]]::new()
}

process {
    $propHash = @{}
    ([xml]$_.$SourcePropertyName).Properties.property
    | ForEach-Object { 
        $null = $PropertyKeys.Add($_.key)
        $propHash[$_.key] = $_.'#text'
    }

    $_.$SourcePropertyName = $propHash

    $null = $collection.Add($_)
}

end {
    $PropertyKeys = $PropertyKeys | Sort-Object -Unique

    $collection | ForEach-Object {
        $entry = $_
        $PropertyKeys | ForEach-Object {
            if ($entry.$_ -and $entry.$SourcePropertyName[$_]) {
                if ($entry.$_ -ne $entry.$SourcePropertyName[$_]) {
                    $entry.$_ = $entry.$_, $entry.$SourcePropertyName[$_]
                }
            } else {
                if ($entry.$_) {
                    # do nothing when the properties value is empty
                } else {
                    $null = $entry | Add-Member -Force -MemberType NoteProperty -Name $_ -Value $entry.$SourcePropertyName[$_]
                }
            }
        }

        $null = $entry.PsObject.Properties.Remove($SourcePropertyName)
    }

    return $collection
}