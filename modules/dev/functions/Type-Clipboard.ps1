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

$KeyboardLayoutSignature = @'
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern short VkKeyScan(char character);
'@
Add-Type `
    -MemberDefinition $KeyboardLayoutSignature `
    -Name KeyboardLayout `
    -Namespace PsClipboardTyper

$KeyboardEventSignature = @'
    private const uint KeyUp = 0x0002;
    private const byte ShiftKey = 0x10;
    private const byte ControlKey = 0x11;
    private const byte AltKey = 0x12;

    [DllImport("user32.dll")]
    private static extern void keybd_event(
        byte virtualKeyCode,
        byte scanCode,
        uint flags,
        UIntPtr extraInfo
    );

    [DllImport("user32.dll")]
    private static extern uint MapVirtualKey(uint code, uint mapType);

    private static void PressKey(byte virtualKeyCode)
    {
        byte scanCode = (byte)MapVirtualKey(virtualKeyCode, 0);
        keybd_event(
            virtualKeyCode,
            scanCode,
            0,
            UIntPtr.Zero
        );
    }

    private static void ReleaseKey(byte virtualKeyCode)
    {
        byte scanCode = (byte)MapVirtualKey(virtualKeyCode, 0);
        keybd_event(
            virtualKeyCode,
            scanCode,
            KeyUp,
            UIntPtr.Zero
        );
    }

    public static void SendModifiedKey(
        byte virtualKeyCode,
        byte modifierState,
        int modifierSettleMs,
        int keyPressMs
    )
    {
        bool shiftPressed = false;
        bool controlPressed = false;
        bool altPressed = false;

        try
        {
            if ((modifierState & 1) != 0)
            {
                PressKey(ShiftKey);
                shiftPressed = true;
            }

            if ((modifierState & 2) != 0)
            {
                PressKey(ControlKey);
                controlPressed = true;
            }

            if ((modifierState & 4) != 0)
            {
                PressKey(AltKey);
                altPressed = true;
            }

            System.Threading.Thread.Sleep(modifierSettleMs);

            PressKey(virtualKeyCode);
            try
            {
                System.Threading.Thread.Sleep(keyPressMs);
            }
            finally
            {
                ReleaseKey(virtualKeyCode);
            }

            System.Threading.Thread.Sleep(modifierSettleMs);
        }
        finally
        {
            if (altPressed)
            {
                ReleaseKey(AltKey);
            }

            if (controlPressed)
            {
                ReleaseKey(ControlKey);
            }

            if (shiftPressed)
            {
                ReleaseKey(ShiftKey);
            }

            System.Threading.Thread.Sleep(modifierSettleMs);
        }
    }
'@
Add-Type `
    -MemberDefinition $KeyboardEventSignature `
    -Name KeyboardEvent `
    -Namespace PsClipboardTyper

function Test-KeyDown {
    param([int]$VirtualKeyCode)

    return ([PsClipboardTyper.KeyState]::GetAsyncKeyState($VirtualKeyCode) -band 0x8000) -ne 0
}

function TypeY {
    param(
        [int]$Timeout = 5,
        [int]$DelayMs = 20,
        [int]$ModifierSettleMs = 75,
        [int]$KeyPressMs = 20,
        [int]$ChunkSize = 50,
        [int]$ChunkPauseMs = 100,
        [string]$Text
    )

    if ($Timeout) {
        Timeout $Timeout
    }

    $lineFeedCharacter = "`n"
    $normalizedText = $Text.Replace("`r`n", "`n").Replace("`r", $lineFeedCharacter)
    $lineFeedCharacterCode = [int][char]$lineFeedCharacter
    $characterIndex = 0

    foreach ($character in $normalizedText.ToCharArray()) {
        $keyMapping = [PsClipboardTyper.KeyboardLayout]::VkKeyScan($character)
        $modifierState = ($keyMapping -shr 8) -band 0x07
        $usesModifier = $keyMapping -ne -1 -and $modifierState -ne 0

        if ($usesModifier) {
            $virtualKeyCode = [byte]($keyMapping -band 0xFF)
            [PsClipboardTyper.KeyboardEvent]::SendModifiedKey(
                $virtualKeyCode,
                [byte]$modifierState,
                $ModifierSettleMs,
                $KeyPressMs
            )
        }
        else {
            $toSend = switch ($character) {
                { [int][char]$_ -eq $lineFeedCharacterCode } { '{ENTER}' }
                ' ' { ' ' }
                default { "{$_}" }
            }

            [System.Windows.Forms.SendKeys]::SendWait($toSend)
            [System.Windows.Forms.SendKeys]::Flush()
            Start-Sleep -Milliseconds $DelayMs
        }

        Write-Host '.' -NoNewline

        $characterIndex++
        if ($ChunkSize -gt 0 -and $characterIndex % $ChunkSize -eq 0) {
            Start-Sleep -Milliseconds $ChunkPauseMs
        }
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
