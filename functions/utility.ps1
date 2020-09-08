function Get-LastWriteTime {
    param(
        [string] $filter = "",
        [string] $path = "."
    )

    Get-ChildItem -Directory $path -Recurse -Filter $filter | % { $_.LastWriteTimeUtc } | Sort-Object -Descending -Top 1
    #Get-ChildItem $path -Recurse -Filter $filter | % { $_.LastWriteTimeUtc } | Measure -Maximum
}

# . $profile; $block = { 1..20 | % { $wait = (Get-Random -Maximum 3 -Minimum 0); Start-Sleep $wait ; Write-Output "$_ $wait" }}; Start-Parallel $block,$block,$block,$block;
function Write-JobOutput {
    param(
        $jobs,
        $colors = @("Blue", "Red", "Cyan", "Green", "Magenta")
    )
    $colorCount = $colors.Length
    $jobs | ForEach-Object { $i = 1 } {
        $fgColor = $colors[($i - 1) % $colorCount]
        $out = $_ | Receive-Job
        $out = $out -split [System.Environment]::NewLine
        $out | ForEach-Object {
            Write-Host "$i> "-NoNewline -ForegroundColor $fgColor
            Write-Host $_
        }
        
        $i++
    }
}

function Start-Parallel {
    param(
        [ScriptBlock[]]
        [Parameter(Position = 0)]
        $ScriptBlock,

        [Object[]]
        [Alias("arguments")]
        $parameters,

        [Alias("sleep")]
        $pollSleepMilliseconds = 250,

        [Alias("init")]
        [scriptblock] $initializationScript,

        [Alias("input")]
        [Object]$inputObject
    )

    $jobs = $ScriptBlock | ForEach-Object { 
        Start-Job -ScriptBlock $_ -InitializationScript $initializationScript -ArgumentList $parameters -InputObject $input
    }

    try {
        while (($jobs | Where-Object { $_.State -ieq "running" } | Measure-Object).Count -gt 0) {
            Write-JobOutput -jobs $jobs
            # process needs some time to breathe
            Start-Sleep -Milliseconds $pollSleepMilliseconds
        }
    }
    finally {
        Write-Host "Stopping Parallel Jobs ..."
        $jobs | Stop-Job
        Write-JobOutput -jobs $jobs
        $jobs | Remove-Job -Force
        Write-Host "Stopped all jobs."
    }
}

function Restart-Elevated {
    param($script = $MyInvocation.PSCommandPath)

    if (!$IsWindows) {
        return
    }

    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        $powserShellExecutable = (Get-Process -id $pid | Get-Item).FullName
        $workingDirectory = Get-Location

        Start-Process -Verb RunAs -FilePath $powserShellExecutable -ArgumentList "`"$script`"" -WorkingDirectory $workingDirectory -Wait
        exit
    }
}

function Confirm-Windows {
    if (!$IsWindows) {
        Throw "Cannot confirm windows envoronment. Environment is Windows: $IsWindows, is Linux: $IsLinux, is Mac: $IsMacOS"
    }
}
