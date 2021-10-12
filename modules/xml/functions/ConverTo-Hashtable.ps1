[CmdletBinding()]
[OutputType([string])]

param(
    [Parameter(ValueFromPipeline=$true)]
    [Microsoft.PowerShell.Commands.SelectXmlInfo] $Xml,
    [switch] $AsPSObject
)

$Xml | Select-Object -ExpandProperty Node `
    | ForEach-Object {
        $node = $_
        $result = @{}
        $node | Get-Member -MemberType Property `
            | Select-Object -ExpandProperty Name `
            | ForEach-Object {
                $result[$_] = $node | Select-Object -ExpandProperty $_
            }

        if ($AsCustomObject) {
            [pscustomobject]$result
        } else {
            $result
        }
    }