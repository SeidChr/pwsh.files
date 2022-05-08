# utilizes the fastes loop available in powershell in order to repeat a certain command.

param(
    [Parameter(ValueFromPipeline, Mandatory)]
    $InputObject,

    [Parameter(Mandatory, Position = 0)]
    [ValidateRange(2, [long]::MaxValue)]
    [long] $Times
)

process {
    [ScriptBlock]::Create("foreach (`$null in 1..$Times) { $_ }").Invoke()
}
