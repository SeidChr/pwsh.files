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
        $wshell.SendKeys("{$_}"); 
        Start-Sleep -Milliseconds $DelayMs
    }
}

function TypeY {
    param([int]$Timeout = 5, [int]$DelayMs = 20, [string] $Text)
    Add-Type -AssemblyName System.Windows.Forms
    if ($Timeout) {
        Timeout $Timeout
    }
    $Text.ToCharArray() | ForEach-Object {
        # Write-Host ([int][char]$_) $_
        $toSend = switch ($_) {
            { [int][char]$_ -eq 13 } { '{ENTER}' } # `r -> newline
            { [int][char]$_ -eq 10 } { '' } # `n -> nothing
            ' ' { ' ' }
            default { "{$_}" }
        }
        
        [System.Windows.Forms.SendKeys]::SendWait($toSend)
        Start-Sleep -Milliseconds $DelayMs
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

    if ($strg -and $alt -and $x) {
        $clipboard = Get-Clipboard -Raw
        Write-Host "Detected 'Paste'. Pasting '$clipboard'." -NoNewline
        while ([PsKeyLog.Keyboard]::GetAsyncKeyState(17) -and [PsKeyLog.Keyboard]::GetAsyncKeyState(18)) {}
        Write-Host "."
        Start-Sleep -Milliseconds 50
        TypeY -Timeout:0 -Text:$clipboard
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
   #0..255 |% {     #    $key = $_    #    $result = [PsKeyLog.Keyboard]::GetAsyncKeyState($_)    #    if ($result -ne 0) {    #        "$($key): $result"    #    }    #}