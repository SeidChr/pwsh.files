param(
    [Parameter(ValueFromPipeline)]
    [xml] $InputObject
)

begin {
    $stringWriter = New-Object System.IO.StringWriter
    $xmlWriter = New-Object System.XMl.XmlTextWriter $stringWriter
    $xmlWriter.Formatting = "indented"
    $xmlWriter.Indentation = 4

    $stringBuilder = $stringWriter.GetStringBuilder()
}

process {
    $InputObject.WriteContentTo($XmlWriter)
    $xmlWriter.Flush()
    $stringWriter.Flush()

    # return result
    $stringWriter.ToString()
    
    # clear string writer
    $null = $stringBuilder.Remove(0, $stringBuilder.Length)
}

# test: "<test name=`"testname`"><testing/><start>some</start><end>test</end><other/><evenMore/></test>","<test2>bla</test2>" |% {[xml]$_} | ConvertFrom-Xml