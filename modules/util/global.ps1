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

    $Selection = $Choices | ForEach-Object { New-Object System.Management.Automation.Host.ChoiceDescription $_ }
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
                    Invoke-WebRequest $urlEntry -TimeoutSec ([int](($ThresholdMs * 2) / 1000))
                    $ProgressPreference = $progressBackup
                } catch {
                } 
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
                    $msColor = if ($result.ThresholdReached) {
                        [ConsoleColor]::Red 
                    } else {
                        [ConsoleColor]::Green 
                    }
                    $barColor = if ($result.ThresholdReached) {
                        [ConsoleColor]::Red 
                    } else {
                        $defaultFgColor 
                    }
                    $formattedMilliseconds = "{0,6:0}" -f [Math]::Abs($result.Measured)

                    Write-Host ($result.Date.ToString() + $distance) -NoNewline
                    Write-Host ($formattedMilliseconds + $distance) -NoNewline -ForegroundColor $msColor
                    
                    $barMaxSegments = $host.UI.RawUI.WindowSize.Width - $host.UI.RawUI.CursorPosition.X - 2;
                    $barSegments = ($barMaxSegments / 100) * $result.Percentage #$ms / 10
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

# avoids changes on a variable to propagate into closures
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

# keeps the order of members in the object
# its like insert-or-update, where insert will insert at the end and update will keep the order.
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
# Allows my to easily collect the last commands result while also writing it to console.
# Its basically an alias for 'Tee-Object -Variable' which is not as straight forward
# when you want to catch list elements.
function _ { 
    begin { 
        $pipe = { Set-Variable -Name LASTRESULT -Scope 1 }.GetSteppablePipeline()
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

# using module PSScriptAnalyzer
# TODO: add module-check and automatic installation
function Format {
    param([string] $Path)
    Invoke-Formatter -ScriptDefinition (Get-Content $Path -Raw) -Settings CodeFormattingOTBS | Set-Content $Path
}

function Send-Bytes {
    param(
        [string] $To, 
        [string] $Arguments
    )

    begin {
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.RedirectStandardInput = $true
        $startInfo.FileName = $To
        $startInfo.Arguments = $Arguments

        $process = [System.Diagnostics.Process]::Start($startInfo)
        $inputStream = $process.StandardInput.BaseStream
    }

    process {
        $inputStream.WriteByte([byte]$_)
    }

    end {
        $inputStream.Flush()
        $inputStream.Close()
        
        $process.WaitForExit()
    }
}

filter ConvertFrom-Base64 {
    [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))
}

function Initialize-SecureStorage {
    param($VaultName = "LocalStore")

    if (-not (Get-Module "Microsoft.PowerShell.SecretManagement" -ListAvailable)) {
        Install-Module -Name Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force
    }
    if (-not (Get-Module "Microsoft.PowerShell.SecretStore" -ListAvailable)) {
        Install-Module -Name Microsoft.PowerShell.SecretStore -Repository PSGallery -Force
    }

    Import-Module Microsoft.PowerShell.SecretManagement
    Import-Module Microsoft.PowerShell.SecretStore

    $password = Read-Host "Enter the SecretStore-Module-Password" -AsSecureString
    $passwordValid = $false
    do {
        try {
            # will also set up a new passwort if no password has been set yet.
            Unlock-SecretStore -Password $password
            $passwordValid = $true
        } catch {
            Write-Host "Unable to unlock SecretStore-Module with given Password."
            $password = Read-Host "Enter the correct SecretStore-Module-Password" -AsSecureString
        }
    } while (-not $passwordValid)
    $password | Export-Clixml -Path "~\password.xml"

    $secretVault = Get-SecretVault $VaultName -ErrorAction SilentlyContinue
    if ($secretVault)  {
        if (-not $secretVault.IsDefault) {
            Set-SecretVaultDefault -SecretVault $secretVault
        }
    } else {
        Register-SecretVault -ModuleName Microsoft.PowerShell.SecretStore -Name $VaultName -DefaultVault
    }

    $storeConfiguration = @{
        Authentication = 'Password'
        PasswordTimeout = 3600 # 1 hour
        Interaction = 'None'
        Confirm = $false
    }

    Set-SecretStoreConfiguration @storeConfiguration
}

# https://learn.microsoft.com/en-us/powershell/utility-modules/secretmanagement/how-to/using-secrets-in-automation?view=ps-modules
function Unlock {
    $password = Import-Clixml -Path ~\password.xml
    Unlock-SecretStore -Password $password
}