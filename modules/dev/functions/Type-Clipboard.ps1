$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);
'@
Add-Type -MemberDefinition $Signature -Name KeyState -Namespace PsClipboardTyper

$FocusSignature = @'
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr windowHandle);
'@
Add-Type -MemberDefinition $FocusSignature -Name WindowFocus -Namespace PsClipboardTyper

function Test-KeyDown {
    param([int]$VirtualKeyCode)

    return ([PsClipboardTyper.KeyState]::GetAsyncKeyState($VirtualKeyCode) -band 0x8000) -ne 0
}

function TypeY {
    param([int]$Timeout = 5, [int]$DelayMs = 20, [string] $Text)
    if ($Timeout) {
        Timeout $Timeout
    }

    $lineFeedCharacter = "`n"
    $normalizedText = $Text.Replace("`r`n", "`n").Replace("`r", $lineFeedCharacter)
    $lineFeedCharacterCode = [int][char]$lineFeedCharacter

    $normalizedText.ToCharArray() | ForEach-Object {
        $toSend = switch ($_) {
            { [int][char]$_ -eq $lineFeedCharacterCode } { '{ENTER}' }
            ' ' { ' ' }
            default { "{$_}" }
        }

        [System.Windows.Forms.SendKeys]::SendWait($toSend)
        Write-Host '.' -NoNewline
        Start-Sleep -Milliseconds $DelayMs
    }
}

Add-Type -AssemblyName System.Windows.Forms

Write-Host 'Press Media Next to type the clipboard contents.'

$triggerKeyCode = [uint32][System.Windows.Forms.Keys]::MediaNextTrack
$inputSettleDelayMs = 200

while ($true) {
    $triggerKeyIsDown = Test-KeyDown $triggerKeyCode

    if ($triggerKeyIsDown) {
        $targetWindowHandle = [PsClipboardTyper.WindowFocus]::GetForegroundWindow()
        $clipboard = $null
        $clipboardReadSucceeded = $true

        try {
            $clipboard = Get-Clipboard -Raw -ErrorAction Stop
        }
        catch {
            $clipboardReadSucceeded = $false
        }

        while (Test-KeyDown $triggerKeyCode) {
            Start-Sleep -Milliseconds 10
        }

        if (-not $clipboardReadSucceeded) {
            Write-Warning 'Clipboard text could not be read. Nothing was typed.'
            continue
        }

        if ([string]::IsNullOrEmpty($clipboard)) {
            Write-Warning 'The clipboard does not contain text. Nothing was typed.'
            continue
        }

        Write-Host 'Detected trigger. Typing clipboard contents: ' -NoNewline
        [void][PsClipboardTyper.WindowFocus]::SetForegroundWindow($targetWindowHandle)
        Start-Sleep -Milliseconds $inputSettleDelayMs

        try {
            TypeY -Timeout:0 -Text:$clipboard
            Write-Host ' Finished.'
        }
        catch {
            Write-Host ' Failed.'
            Write-Warning "Typing failed: $($_.Exception.Message)"
        }
    }

    Start-Sleep -Milliseconds 20
}
