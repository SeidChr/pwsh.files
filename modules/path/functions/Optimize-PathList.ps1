param(
    $PathList
)

$cleanedPath = New-Object System.Collections.Generic.List[string]

$PathList `
    | Where-Object { ![string]::IsNullOrWhiteSpace($_) } `
    | ForEach-Object {
        $newPart = $_.TrimEnd('\/\\')
        if ($cleanedPath -cNotContains $newPart) {
            $cleanedPath.Add($newPart)
        }
    }

return $cleanedPath.ToArray()