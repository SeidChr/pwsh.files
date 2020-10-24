param(
    [Parameter(Mandatory = $true)]
    [string] $Url,
    [Net.Http.HttpMethod] $Method,
    [Net.Http.HttpContent] $Content = $null,
    [switch] $Block
)

Write-Verbose "Measuring $Method Request"

$client = [Net.Http.HttpClient]::new()
$stopwatch = [Diagnostics.Stopwatch]::new()
$result = $null;

$version = $PSVersionTable.PSEdition + "-" + $PSVersionTable.PSVersion
$userAgent = "Mozilla/5.0 pwsh/$version Measure-WebRequest/0.1"

$client.DefaultRequestHeaders.Add("User-Agent", $userAgent);
$request = [Net.Http.HttpRequestMessage]::new($Method, $Url)

if ($Content) {
    Write-Verbose "With Content"
    $request.Content = $content;
}

if ($block) {
    $stopwatch.Start()
    $result = $client.SendAsync($request).GetAwaiter().GetResult()
    $stopwatch.Stop()
} else {
    $stopwatch.Start()
    $task = $client.SendAsync($request)
    while (-not $task.AsyncWaitHandle.WaitOne(200)) { }
    $result = $task.GetAwaiter().GetResult()
    $stopwatch.Stop()
}

$millis = $stopwatch.ElapsedMilliseconds
Write-Verbose "Request took $millis ms."

[PSCustomObject]@{
    Response     = $result
    Milliseconds = $stopwatch.ElapsedMilliseconds
}