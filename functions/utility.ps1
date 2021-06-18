function Get-LastWriteTime {
    param(
        [string] $Filter = "",
        [string] $Path = "."
    )

    $Path = Resolve-Path $Path
    Write-Host $path

    Get-ChildItem -Path $Path -Recurse `
    | ForEach-Object { $_.LastWriteTimeUtc } `
    | Sort-Object -Descending -Top 1
}

function Register-LastWriteTime {
    param(
        [string] $Key,
        [string] $Filter = "",
        [string] $Path = "."
    )

    $lastWriteTime = Get-LastWriteTime -Filter $Filter -Path $Path
    [Environment]::SetEnvironmentVariable("LASTCHANGES_$Key", $lastWriteTime, "Process")
}

function Get-HasChanges {
    param(
        [string] $Key,
        [string] $Path = ".",
        [string] $Filter = ""
    )

    $lastWriteTimeDisk = Get-LastWriteTime -Filter $Filter -Path $Path
    $lastWriteTimeEnv = [Environment]::GetEnvironmentVariable("LASTCHANGES_$Key", "Process")
    if ($lastWriteTimeEnv -ne $lastWriteTimeDisk) { $true } else { $false }
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
        $out = $_ | Receive-Job -ErrorAction Continue
        $out = $out -split [System.Environment]::NewLine
        $out | ForEach-Object {
            Write-Host "$i> " -NoNewline -ForegroundColor $fgColor
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

function Start-Elevated {
    if (!$IsWindows) {
        return
    }

    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )

    $isAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if ($isAdmin) {
        "Already elevated."
    } else {
        $powserShellExecutable = (Get-Process -id $pid | Get-Item).FullName
        $workingDirectory = Get-Location

        Write-Host "Starting Elevated Shell..." -NoNewline
        $null = Start-Process -Verb RunAs -FilePath $powserShellExecutable -WorkingDirectory $workingDirectory
        Write-Host "Started."
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

function Get-ShellNestingLevel {
    $leafProcess = Get-Process -Id $pid
    $leafProcessPath = $leafProcess.Path
    $nestingLevel = 0

    $parentProcess = $leafProcess.Parent;
    while ($parentProcess) {
        if ($parentProcess.Path -eq $leafProcessPath) {
            $nestingLevel++;
        } else {
            break
        }

        $parentProcess = $parentProcess.Parent;
    }

    $nestingLevel
}

# <.SYNOPSIS>
# will return the first process that has not the
# same executable as the current powershell process
function Get-CallingProcess {
    $leafProcess = Get-Process -Id $pid
    $leafProcessPath = $leafProcess.Path

    $parentProcess = $leafProcess.Parent;

    while ($parentProcess) {
        if (-not ($parentProcess.Path -eq $leafProcessPath)) {
            return $parentProcess
        }
        $parentProcess = $parentProcess.Parent
    }
}

function Request-Module {
    param([string]$moduleName)
    If (-not (Get-Module -ErrorAction Ignore -ListAvailable $moduleName)) {
        Install-Module $moduleName -ErrorAction Stop
    }

    Import-Module -ErrorAction Stop $moduleName
}

function Get-EnumValues {
    # get-enumValues -enum "System.Diagnostics.Eventing.Reader.StandardEventLevel"
    param([string]$enum)

    $enumValues = @{}
    [enum]::GetValues([type]$enum) `
        | ForEach-Object { 
            $enumValues.add($_, $_.value__)
        }

    $enumValues
}

function Select-Option {
    # https://social.technet.microsoft.com/wiki/contents/articles/24030.powershell-demo-prompt-for-choice.aspx
    # Select-Option "Programm Extermination" "Quit Or Go On?" "&Continue","&Exterminate" 0
    param(
        [string] $Caption,
        [string] $Message,
        [string[]] $Choices,
        [int] $Default = 0
    )

    $Selection = $Choices | ForEach-Object { new-object System.Management.Automation.Host.ChoiceDescription $_ }
    $Host.UI.PromptForChoice($Caption, $Message, $Selection, $Default)
}

function Measure-Website {
    param (
        [string[]] $Url,
        [int] $Sleep = 5,
        [Alias("AlarmThresholdMs")]
        [Alias("Threshold")]
        [int] $ThresholdMs = 500,
        [switch] $Alarm,
        [int] $AlarmFrequency = 2000,
        [switch] $PassThru,
        [switch] $Progress
    )
    
    while ($true) {
        $Url | ForEach-Object {
            $urlEntry = $_
            $ms = Measure-Command { 
                    try {
                        $progressBackup = $ProgressPreference
                        $ProgressPreference = 'SilentlyContinue'
                        Invoke-WebRequest $urlEntry -TimeoutSec ([int](($ThresholdMs*2)/1000))
                        $ProgressPreference = $progressBackup
                    } catch {} 
                } `
                | Select-Object -ExpandProperty TotalMilliseconds

            $distance = " " * 3
            $percentage = ($ms / $ThresholdMs) * 100

            $result = [PSCustomObject]@{
                Date                = Get-Date
                Measured            = $ms
                Threshold           = $ThresholdMs
                ThresholdReached    = $ms -gt $ThresholdMs
                ThresholdPercentage = $percentage
                Percentage          = [Math]::Min($percentage, 100)
                Url                 = $urlEntry
            }

            if ($Alarm -and $result.ThresholdReached) {
                [Console]::Beep($AlarmFrequency, 100)
            }

            if ($PassThru) {
                $result
            } else {
                if ($Progress) {
                    $progressColorBackup = $host.PrivateData.ProgressBackgroundColor
                    if ($result.ThresholdReached) {
                        $host.PrivateData.ProgressBackgroundColor = "red"
                    }

                    $progressId = [array]::IndexOf($Url, $urlEntry)

                    Write-Progress `
                        -Activity "Measure Website" `
                        -Status ("Response Time: {0} ms ({1:0.00} % of {2} ms)" -f $result.Measured, $result.ThresholdPercentage, $result.Threshold) `
                        -PercentComplete $result.Percentage `
                        -CurrentOperation $urlEntry `
                        -Id $progressId

                    $host.PrivateData.ProgressBackgroundColor = $progressColorBackup

                    if ($result.ThresholdReached) {
                        $message = $result.Date.ToString() `
                            + $distance + ("{0,6:0} ms" -f [Math]::Abs($result.Measured)) `
                            + $distance + $urlEntry

                        Write-Host $message -ForegroundColor Red
                    }
                } else {
                    $suffix = ""

                    $defaultFgColor = $host.UI.RawUI.ForegroundColor
                    $msColor = if ($result.ThresholdReached) { [ConsoleColor]::Red } else { [ConsoleColor]::Green }
                    $barColor = if ($result.ThresholdReached) { [ConsoleColor]::Red } else { $defaultFgColor }
                    $formattedMilliseconds = "{0,6:0}" -f [Math]::Abs($result.Measured)

                    Write-Host ($result.Date.ToString() + $distance) -NoNewline
                    Write-Host ($formattedMilliseconds + $distance) -NoNewline -ForegroundColor $msColor
                    
                    $barMaxSegments = $host.UI.RawUI.WindowSize.Width - $host.UI.RawUI.CursorPosition.X - 2;
                    $barSegments = ($barMaxSegments/100) * $result.Percentage #$ms / 10
                    if ($barSegments -gt $barMaxSegments) {
                        $suffix = "…"
                    }

                    $barSegments = [Math]::Min($barSegments, $barMaxSegments)
                    $bar = ("#" * $barSegments) + $suffix;
                    Write-Host $bar -ForegroundColor $barColor
                }
            }
        }

        Start-Sleep -Seconds 5
    }
}

function Require {
    [cmdletbinding()]
    param(
        [string[]] $Function = "*", 
        [string] $From = "scripts"
    )

    $Function `
        | ForEach-Object { Get-ChildItem $From -Filter "$_.ps1" } `
        | ForEach-Object {
            $functionName = Split-Path -LeafBase $_
            $body = Get-Content $_ -Raw
            #Set-Variable -Name "function:$functionName" -Value "{ $body }"
            Invoke-Expression "function global:$functionName { $body }";
            Write-Verbose "Function $functionName added to scope"
        }
}

function Close {
    # https://github.com/PowerShell/PowerShell/blob/91e7298fd8101b85b17514dfefa41b20a7276ca4/src/System.Management.Automation/engine/Modules/PSModuleInfo.cs#L1340
    # https://github.com/PowerShell/PowerShell/blob/91e7298fd8101b85b17514dfefa41b20a7276ca4/src/System.Management.Automation/engine/lang/scriptblock.cs#L119

    param(
        [Parameter(ValueFromRemainingArguments, Position = 0)]
        [Alias("Variables", "Args", "Arguments", "Var", "Vars", "On")]
        [string[]] $VariableNames,
        [Parameter(ValueFromPipeline, Mandatory, Position = 1)]
        [scriptblock] $Script
    )
    
    $module = [psmoduleinfo]::new($true)

    $VariableNames | ForEach-Object {
        $module.SessionState.PSVariable.Set($_, $(Get-Variable -Name $_).Value)
    }

    $module.NewBoundScriptBlock($s)
}

function Test-MatchAny {
    param(
        [Parameter(ValueFromPipeline)]
        $entity,

        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $regex
    )
    process {
        foreach ($reg in $regex) {
            if ($_ -match $reg) {
                return $true
            }
        }

        return $false
    }
}

function Test-MatchAll {
    param(
        [Parameter(ValueFromPipeline)]
        $entity,

        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $regex
    )
    process {
        foreach ($reg in $regex) {
            if ($_ -notmatch $reg) {
                return $false
            }
        }

        return $true
    }
}

function Select-MatchAny {
    param(
        [Parameter(ValueFromPipeline)]
        $entity,

        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $regex
    )

    process {
        if ($_ | Test-MatchAny $regex) {
            $_
        }
    }
}

function Select-MatchAll {
    param(
        [Parameter(ValueFromPipeline)]
        $entity,

        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $regex
    )

    process {
        if ($_ | Test-MatchAll $regex)
        {
            $_
        }
    }
}

function ConvertTo-QueryString {
    param (
        [Parameter(ValueFromPipeline)]
        $hashtable
    )

    $body = $hashtable.GetEnumerator() `
    | ForEach-Object {
        if ($_.Value -is [array]) {
            $name = $_.Key
            $_.Value | ForEach-Object { @{Key = $name; Value = $_ } }
        } else {
            $_
        }
    } `
    | ForEach-Object { $_.Key + "=" + [System.Web.HttpUtility]::UrlEncode($_.Value, [System.Text.Encoding]::UTF8) } `
    | Join-String -Separator "&"

    if ($body) {
        return "?" + $body
    }
}

function Set-Member {
     param(
         [string] $Name,
         [object] $Value,
         [Parameter(ValueFromPipeline)]
         [object] $InputObject
     )
     process {
         $prop = $_.psobject.Properties[$Name]
         if ($prop) {
             $prop.Value = $Value
         } else {
             $prop = [psnoteproperty]::new($Name, $Value)
             $InputObject.psobject.Properties.Add($prop) 
         }
         return $_                                                      
     }
 }

Set-Alias -Name Enable-Sharing -Value Start-Sharing
function Start-Sharing {
    $global:sharing = $true
    Clear-Host
}

Set-Alias -Name Property -Value Expand-Property
function Expand-Property {
    param([string[]] $Name)
    begin {
        $Name = foreach ($_ in $Name) {
            $_.Split('.') 
        } 
    }
    process {
        $current = $_
        foreach ($propertyName in $Name) {
            $current = $current.$propertyName
        }
        $current
    }
}
