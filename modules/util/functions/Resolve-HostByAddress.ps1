param(
    [string[]] $Address,
    [switch]   $PassThru
)

$ipHostName = @{}

$Address | ForEach-Object -ThrottleLimit 10 -Parallel {
    try { [System.Net.Dns]::GetHostByAddress($_) } catch {}
} | ForEach-Object {
    $hostObject = $_
    foreach ($hostAddress in $hostObject.AddressList) {
        $hostAddressString = "$hostAddress"
        if (($hostAddressString -in $Address) -and (-not $ipHostName[$hostAddressString])) {
            $ipHostName[$hostAddressString] = $hostObject.HostName
            if ($PassThru) {
                @{
                    Address  = $hostAddressString
                    HostName = $hostObject.HostName
                }
            } else {
                Write-Host "Resolved $hostAddressString to $($hostObject.HostName)"
            }
        }
    }
}