param([byte[]]$Content)
Write-Verbose "Creating Http-Content for $($Content.Count) Bytes."
[Net.Http.ByteArrayContent]::new($Content)