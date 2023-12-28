param([int]$Px = 32)

# https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfoa
$code = @'
[DllImport("user32.dll")]
public static extern bool SystemParametersInfo(uint a,uint b,uint c,uint d);
'@
$CursorRefresh = Add-Type -MemberDefinition $code -Name u32 -PassThru
$CursorRefresh::SystemParametersInfo(0x2029, 0, $Px, 0x01)