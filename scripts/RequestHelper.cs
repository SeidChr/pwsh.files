using System;
using System.Threading.Tasks;

public class RequestHelper
{
    public class Response
    {
        public System.Net.Http.HttpResponseMessage Message { get; set; }
        public long Milliseconds { get; set; }
    }

    public Response PostRequest(string url, byte[] bytes, bool block)
    {
        var content = new System.Net.Http.ByteArrayContent(bytes);
        var userAgent = "Mozilla/5.0 Powershell/core-7.0.3 Test-Speed/0.1";
        var client = new System.Net.Http.HttpClient();
        client.DefaultRequestHeaders.Add("User-Agent", userAgent);
        var stopwatch = new System.Diagnostics.Stopwatch();
        System.Net.Http.HttpResponseMessage result = null;

        var request = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Post, url);
        request.Content = content;
        // var request = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Head, url);

        if (block)
        {
            stopwatch.Start();
            //$result = $client.PostAsync($url, $content).GetAwaiter().GetResult()
            result = client.SendAsync(request).GetAwaiter().GetResult();
            stopwatch.Stop();
        }
        else
        {
            stopwatch.Start();
            var task = client.SendAsync(request);
            while (!((System.IAsyncResult) task).AsyncWaitHandle.WaitOne(200)) {}
            result = task.GetAwaiter().GetResult();
            stopwatch.Stop();
        }

        return new Response
        {
            Message = result,
            Milliseconds = stopwatch.ElapsedMilliseconds,
        };
    }
}
