[OutputType([Result])]
param()

class Result {
    [System.IO.FileInfo]$File
    [xml]$Project
}


Get-CsProjectFiles | ForEach-Object {
    [Result]@{
        File = $_
        Project = [XML]($_ | Get-Content -Raw)
    }
}