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
        $powserShellExecutable = (Get-Process -Id $pid | Get-Item).FullName
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
        $powserShellExecutable = (Get-Process -Id $pid | Get-Item).FullName
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
        if ($_ | Test-MatchAll $regex) {
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
    Set-Location ~
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

function Get-NextDateOfWeekday {
    param([DayOfWeek] $DayOfWeek)
    $today = [DateTime]::Now.Date
    $daysToAdd = ( 7 - ( ( [int]$today.DayOfWeek + 7 ) - [int]$DayOfWeek ) % 7 )
    $today.AddDays($daysToAdd)
}

# .SYNOPSIS
# Splits sets of items into multiple groups by number
function Group-Items {
    param (
        [Parameter(ValueFromPipeline)]
        $Item,
        [int] $GroupSize
    )

    begin {
        $joined = @() 
    }
    end {
        , $joined 
    }
    process {
        if ($GroupSize -and (($joined.Count + 1) -gt $GroupSize)) {
            , $joined
            $joined = @()
        }

        $joined += $Item
    }
}

# .Synopsis
# Allows to execute a script for every x items of a list. Groups them beforehand.
# $step = 1000
# $iterations = [Math]::Ceiling(($files.Count / $step))
# for ($i = 0; $i -lt $iterations; $i++) {
#     $fewerFiles = $files | Select-Object -Skip ( $i * $step ) -First $step
#     $Ctx.Load($fewerFiles)
#     $Ctx.ExecuteQuery();
# }

function ForEach-Batch {
    param(
        [Parameter(ValueFromPipeline)]
        $Item,
        [Parameter(Position = 0)]
        [Alias("Of")]
        [int] $BatchSize,
        [Parameter(Position = 1)]
        [scriptblock] $Action
    )

    begin {
        $code = @"
& {
  process
  {
    $Action
  }
}
"@

        $joined = @()
        $pip = [ScriptBlock]::Create($code).GetSteppablePipeline()
        $pip.Begin($true)
    }
    end {
        $pip.Process($joined)
        $pip.End()
    }
    process {
        if ($BatchSize -and (($joined.Count + 1) -gt $BatchSize)) {
            $pip.Process($joined)
            $joined = @()
        }

        $joined += $Item
    }
}

# WIP batching using group-function
# function ForEach-Batch2 {
#     param(
#         [Parameter(ValueFromPipeline)]
#         $Item,
#         [Parameter(Position = 0)]
#         [Alias("Of")]
#         [int] $BatchSize,
#         [Parameter(Position = 1)]
#         [scriptblock] $Action
#     )

#     begin {
#         $pip = { Group-Items -GroupSize $BatchSize | & $Action }.GetSteppablePipeline()
#         $pip.Begin($true)
#     }
#     end {
#         $pip.Process($joined)
#         $pip.End()
#     }
#     process {
#         if ($BatchSize -and (($joined.Count + 1) -gt $BatchSize)) {
#             $pip.Process($joined)
#             $joined = @()
#         }

#         $joined += $Item
#     }
# }

# .Synopsis
# Collects everything piped through it in the variable "LASTRESULT". 
# Can be appended on every pipe in order to just collect the result of the last command 
# so you dont have to assign it into a variable manually.
# Its basically an alias for 'Tee-Object -Variable' which is not as straight forward
# when you want to catch list elements.
# .Example
# 
function _ {
    param($Name = "LASTRESULT")
    begin { 
        $pipe = { Set-Variable -Name $Name -Scope 1 }.GetSteppablePipeline()
        $pipe.Begin($true) 
    }

    process {
        $pipe.Process($_)
        Write-Output -InputObject $_
    }

    end {
        $pipe.End()
    }
}

# .Synopsis
# Allows to echo the pipeline element to the host, so it can be
# read by the user while passing it to the output stream as well.
function Tee-Host { 
    process {
        Write-Host $_
        Write-Output $_
    }
}