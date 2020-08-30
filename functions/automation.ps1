if (-not $isWindows) {
    return
}

function Click-MouseButton
{
    $signature=@'
      [DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
      public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@

    $params = @{
        memberDefinition = $signature
        name = "Win32MouseEventNew"
        namespace = "Win32Functions"
        passThru = $true
    }

    $SendMouseClick = Add-Type @params

    if ($SendMouseClick) {
        $SendMouseClick::mouse_event(0x00000002, 0, 0, 0, 0);
        $SendMouseClick::mouse_event(0x00000004, 0, 0, 0, 0);
    } else {
        "NULL :-("
    }
}