param(
    [Parameter(ValueFromPipeline)]
    [xml] $InputObject
)

process {
    $stringWriter = New-Object System.IO.StringWriter
    $xmlWriter = New-Object System.XMl.XmlTextWriter $stringWriter
    $xmlWriter.Formatting = "indented"
    $xmlWriter.Indentation = 4

    $InputObject.WriteContentTo($XmlWriter)
    $xmlWriter.Flush()
    $stringWriter.Flush()

    # return result
    $stringWriter.ToString()
    
    # clear stream variables
    Remove-Variable "stringWriter", "xmlWriter" -Scope Local
}

# test: "<test name=`"testname`"><testing/><start>some</start><end>test</end><other/><evenMore/></test>","<test2>bla</test2>" |% {[xml]$_} | ConvertFrom-Xml