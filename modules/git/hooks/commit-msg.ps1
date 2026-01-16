$branch = git rev-parse --abbrev-ref HEAD
$messageFile = $args[0]
$messageContent = Get-Content -Path $messageFile -Raw
$branchLeaf = $branch.Split('/')[-1]
$ticketId = $branchLeaf | Select-String -Pattern '\d{3,}' | ForEach-Object Matches | Select-Object -First 1 | ForEach-Object Value

$prefix = if ($ticketId) {
    (" `#" + $ticketId)
} else { 
    $branchLeaf 
}

$branch, $messageFile, $messageContent, $ticketId, $prefix | ConvertTo-Json -Depth 100 | Write-Host

$messageStart = $prefix + ": "

if (-not [regex]::IsMatch('\#\d{3,}')) {
#if (-not $messageContent.StartsWith($messageStart)) {
    $messageContent = $messageStart + $messageContent
    Set-Content -Path $messageFile -Value $messageContent
}