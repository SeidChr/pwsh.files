$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsKeyLog

function TypeX {
    param([int]$Timeout = 5, [int]$DelayMs = 20, [string] $Text)
    $wshell = New-Object -ComObject wscript.shell;
    if ($Timeout) {
        Timeout $Timeout
    }
    $Text.ToCharArray() | ForEach-Object {
        $wshell.SendKeys("{$_}"); Start-Sleep -Milliseconds $DelayMs
    }
}

while ($true) {
    # strg + alt + roll
    # roll = 145
    # ins = 45
    # left mouse = 1
    # middle mouse = 4
    $strgState = [PsKeyLog.Keyboard]::GetAsyncKeyState(17)
    $altState = [PsKeyLog.Keyboard]::GetAsyncKeyState(18)
    $xState = [PsKeyLog.Keyboard]::GetAsyncKeyState(4)
    $strg = $strgState -in -32767, -32768
    $alt = $altState -in -32767, -32768
    $x = $xState -eq -32767
    # $current = "$strgState $altState $insState"
    # #if ($current -ne $last) {
    # #   $last = $current
    #    $current
    # #}
    if ($strg -and $alt -and $x) {
        while ([PsKeyLog.Keyboard]::GetAsyncKeyState(17) -and [PsKeyLog.Keyboard]::GetAsyncKeyState(18)) {}
        Start-Sleep -Milliseconds 50
        TypeX -Timeout:0 -Text:(Get-Clipboard)
    }
    Start-Sleep -Milliseconds 200
    #0..255 |% { 
    #    $key = $_
    #    $result = [PsKeyLog.Keyboard]::GetAsyncKeyState($_)
    #    if ($result -ne 0) {
    #        "$($key): $result"
    #    }
    #}
}



