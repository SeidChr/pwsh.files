<#
.SYNOPSIS
Turns off the displays when a specific USB device is disconnected.

.PARAMETER Identifier
USB/PnP device identifier to watch. By default this must exactly match one of
the device's DeviceID, PNPDeviceID, Name, or Caption values.

.PARAMETER PollSeconds
How often connected devices are checked. The default is 2 seconds.

.PARAMETER Wildcard
Allows the identifier to use PowerShell wildcard matching, for example
'*VID_1234&PID_5678*'.

.EXAMPLE
.\Watch-UsbDisconnectScreensaver.ps1 'USB\VID_1234&PID_5678\ABCDEF'

.EXAMPLE
.\Watch-UsbDisconnectScreensaver.ps1 '*VID_1234&PID_5678*' -Wildcard

.NOTES
The display-off command causes monitors with automatic input switching to
select another active input. On Modern Standby systems, disabling Modern
Standby may be required to prevent display-off from also suspending the system.
Run Set-ModernStandbyOverride without parameters to inspect the override. Run
Set-ModernStandbyOverride -Disable from an elevated PowerShell session to
disable Modern Standby after the next Windows restart.

Ways to find the USB identifier in Windows:

1. Device Manager
   - Connect the USB device.
   - Open Device Manager.
   - Find the device, often under "Universal Serial Bus devices",
     "Human Interface Devices", "Keyboards", "Mice and other pointing devices",
     "Ports (COM & LPT)", or "Disk drives".
   - Open Properties.
   - Go to the Details tab.
   - Select "Device instance path" or "Hardware Ids".
   - Use the shown value as the Identifier, or use a stable part of it with
     -Wildcard, such as '*VID_1234&PID_5678*'.

2. PowerShell list while the device is connected
   Get-CimInstance Win32_PnPEntity |
       Where-Object { $_.PNPDeviceID -like 'USB*' } |
       Select-Object Name, PNPDeviceID

3. PowerShell compare before and after connecting the device
   Run this before connecting the device:
       Get-CimInstance Win32_PnPEntity |
           Select-Object Name, PNPDeviceID |
           Export-Clixml .\before-usb.xml

   Connect the device, then run:
       $before = Import-Clixml .\before-usb.xml
       $after = Get-CimInstance Win32_PnPEntity | Select-Object Name, PNPDeviceID
       Compare-Object $before $after -Property PNPDeviceID -PassThru |
           Select-Object Name, PNPDeviceID
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Identifier,

    [int] $PollSeconds = 2,

    [switch] $Wildcard
)

$ErrorActionPreference = 'Stop'

Add-Type '[DllImport("user32.dll")]public static extern int PostMessage(int a, int b, int c, int d);' -Name ScreensaverNative -Namespace UsbWatch | Out-Null

function Disable-Monitors {
    [UsbWatch.ScreensaverNative]::PostMessage(-1, 0x0112, 0xF170, 2) | Out-Null
}

function Test-DevicePresent {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DeviceIdentifier,

        [bool] $UseWildcard
    )

    $devices = Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.ConfigManagerErrorCode -eq 0 }

    foreach ($device in $devices) {
        $values = @(
            $device.DeviceID
            $device.PNPDeviceID
            $device.Name
            $device.Caption
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        foreach ($value in $values) {
            if ($UseWildcard) {
                if ($value -like $DeviceIdentifier) {
                    return $true
                }
            }
            elseif ($value -eq $DeviceIdentifier) {
                return $true
            }
        }
    }

    return $false
}

if ($PollSeconds -lt 1) {
    throw 'PollSeconds must be 1 or greater.'
}

$wasPresent = Test-DevicePresent -DeviceIdentifier $Identifier -UseWildcard $Wildcard.IsPresent

while ($true) {
    Start-Sleep -Seconds $PollSeconds

    $isPresent = Test-DevicePresent -DeviceIdentifier $Identifier -UseWildcard $Wildcard.IsPresent

    if ($wasPresent -and -not $isPresent) {
        Write-Host 'Turn Off Screens'
        Disable-Monitors
    }

    $wasPresent = $isPresent
}
