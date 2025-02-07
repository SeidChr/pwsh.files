function Initialize-Windows10SystemClock {
    # set a registry value to show the seconds in the taskbar-clock
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -Value 1 -Type DWord
    
    # restarting explorer is required to actually show the seconds on the clock in the taskbar
    Stop-Process -Name explorer -Force
    Start-Process explorer
}