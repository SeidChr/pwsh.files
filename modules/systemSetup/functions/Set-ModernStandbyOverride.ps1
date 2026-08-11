<#
.SYNOPSIS
Shows, disables, or restores the default Windows Modern Standby configuration.

.DESCRIPTION
Manages the following system-wide registry value:

HKLM:\SYSTEM\CurrentControlSet\Control\Power\PlatformAoAcOverride

Using -Disable creates the DWORD value PlatformAoAcOverride with value 0.
Windows evaluates this value during startup, so a restart is required before
the change takes effect.

Using -RestoreDefault removes PlatformAoAcOverride and lets Windows select its
default power model again. Restoring the default also requires a restart.

Disabling Modern Standby does not add support for traditional S3 sleep. If the
computer firmware does not support S3, Hibernate may be the only remaining
suspend state. Verify the result after restarting with:

powercfg /a

Run changes from an elevated PowerShell session. Calling the function without
a parameter only reads the current configuration and does not require
elevation.

.PARAMETER Disable
Disables Modern Standby by setting PlatformAoAcOverride to 0.

.PARAMETER RestoreDefault
Removes PlatformAoAcOverride and restores Windows' default power-model
selection.

.EXAMPLE
Set-ModernStandbyOverride

Shows whether the registry override is absent, disabled, or contains an
unexpected custom value.

.EXAMPLE
Set-ModernStandbyOverride -Disable

Disables Modern Standby after the next Windows restart.

.EXAMPLE
Set-ModernStandbyOverride -RestoreDefault

Removes the override and restores the default behavior after the next restart.

.EXAMPLE
Set-ModernStandbyOverride -Disable -WhatIf

Shows the registry change without applying it.

.NOTES
This setting affects the entire Windows installation, not only the USB
disconnect watcher. No automatic restart is performed.

Microsoft's formal Modern Standby documentation explains the S0 power model
and states that switching between Modern Standby and S3 is not supported as a
normal Windows configuration change. The PlatformAoAcOverride registry method
is documented in Microsoft Q&A rather than the formal Windows hardware
documentation. Its behavior therefore depends on the Windows build, firmware,
drivers, and available sleep states.

Source references:

1. PlatformAoAcOverride registry key and value 0
   Microsoft Q&A: "Disabling modern standby in Windows 24H2"
   This is the source for creating the DWORD PlatformAoAcOverride with value 0
   under HKLM\SYSTEM\CurrentControlSet\Control\Power.
   https://learn.microsoft.com/en-us/answers/questions/3941311/

2. Removing PlatformAoAcOverride to restore Modern Standby
   Microsoft Q&A: "How do I re-enable my modern standby sleep mode (S0)?"
   This is the source for deleting PlatformAoAcOverride and restarting Windows.
   https://learn.microsoft.com/en-us/answers/questions/4019057/

3. Modern Standby behavior and power-model limitations
   Microsoft Learn: "Modern Standby"
   This explains S0 Low Power Idle and states that switching between S3 and
   Modern Standby is not supported as a normal Windows configuration change.
   https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby

4. Available Windows system power states
   Microsoft Learn: "System power states"
   This explains S0 Modern Standby, S1 through S3, and hibernation.
   https://learn.microsoft.com/en-us/windows/win32/power/system-power-states

5. Verifying available sleep states with powercfg
   Microsoft Learn: "Powercfg command-line options"
   This documents powercfg and its available-sleep-states reporting.
   https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options

.LINK
https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby

.LINK
https://learn.microsoft.com/en-us/windows/win32/power/system-power-states

.LINK
https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options

.LINK
https://learn.microsoft.com/en-us/answers/questions/3941311/

.LINK
https://learn.microsoft.com/en-us/answers/questions/4019057/
#>

[CmdletBinding(
    DefaultParameterSetName = 'Status',
    SupportsShouldProcess = $true
)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Disable')]
    [switch] $Disable,

    [Parameter(Mandatory = $true, ParameterSetName = 'RestoreDefault')]
    [switch] $RestoreDefault
)

if (-not $IsWindows) {
    throw 'Modern Standby is a Windows-only feature.'
}

$powerRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'
$valueName = 'PlatformAoAcOverride'

function Get-OverrideState {
    $powerSettings = Get-ItemProperty -LiteralPath $powerRegistryPath
    $valueProperty = $powerSettings.PSObject.Properties[$valueName]

    if ($null -eq $valueProperty) {
        return [pscustomobject]@{
            State = 'Windows default'
            RegistryValue = $null
            RestartRequired = $false
        }
    }

    $registryValue = [uint32] $valueProperty.Value
    $state = if ($registryValue -eq 0) {
        'Modern Standby disabled'
    }
    else {
        'Unexpected custom value'
    }

    return [pscustomobject]@{
        State = $state
        RegistryValue = $registryValue
        RestartRequired = $false
    }
}

if ($PSCmdlet.ParameterSetName -eq 'Status') {
    Get-OverrideState
    return
}

$principal = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
$isAdministrator = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdministrator -and -not $WhatIfPreference) {
    throw @'
Changing the Modern Standby override requires an elevated PowerShell session.
Run Elevate-Here, then run this command again.
'@
}

$changed = $false

if ($PSCmdlet.ParameterSetName -eq 'Disable') {
    $target = "$powerRegistryPath\$valueName"

    if ($PSCmdlet.ShouldProcess($target, 'Set DWORD value to 0')) {
        New-ItemProperty `
            -LiteralPath $powerRegistryPath `
            -Name $valueName `
            -PropertyType DWord `
            -Value 0 `
            -Force |
            Out-Null

        $changed = $true
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'RestoreDefault') {
    $currentState = Get-OverrideState

    if (
        $null -ne $currentState.RegistryValue -and
        $PSCmdlet.ShouldProcess(
            "$powerRegistryPath\$valueName",
            'Remove registry value'
        )
    ) {
        Remove-ItemProperty `
            -LiteralPath $powerRegistryPath `
            -Name $valueName

        $changed = $true
    }
}

$result = Get-OverrideState
if ($changed) {
    $result.RestartRequired = $true
    Write-Warning 'Restart Windows for the Modern Standby change to take effect.'
}

$result
