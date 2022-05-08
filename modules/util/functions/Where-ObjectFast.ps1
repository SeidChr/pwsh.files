# https://powershell.one/tricks/performance/pipeline
param
(
    [ScriptBlock]
    $FilterScript
)

begin {
    # construct a hard-coded anonymous simple function:
    $code = @"
& {
  process { 
    if ($FilterScript) 
    { `$_ }
  }
}
"@
    # turn code into a scriptblock and invoke it
    # via a steppable pipeline so we can feed in data
    # as it comes in via the pipeline:
    $pip = [ScriptBlock]::Create($code).GetSteppablePipeline()
    $pip.Begin($true)
}
process {
    # forward incoming pipeline data to the custom scriptblock:
    $pip.Process($_)
}
end {
    $pip.End()
}