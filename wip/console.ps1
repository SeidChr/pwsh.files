Add-Type -TypeDefinition @"
using System;
using System.Linq;
using System.Runtime.InteropServices;

public class NativeConsole
{
    internal enum Channel : int
    {
        StdInput = -10,

        StdOutput = -11,

        StdError = -12,
    }

    public static void Write(params string[] texts)
    {
        var handle = GetStdHandle(Channel.StdOutput);
        short width = (short)texts.Select(t => t.Length).Max();
        short height = (short)texts.Length;

        var buffer = new CharInfo[height * width];
        var targetRegion = new Rectangle { Top = 0, Left = 0, Bottom = height, Right = width };
        var blank = new CharInfo { UnicodeChar = ' ', Attributes = 0x0000 };

        for (int y = 0; y < height; y++)
        {
            var chars = texts[y]
                .Select(c => new CharInfo { UnicodeChar = c, Attributes = 0x0000 })
                .ToArray();

            for (int x = 0; x < chars.Length; x++)
            {
                buffer[(y * width) + x] = chars[x];
            }

            for (int x = chars.Length; x < width; x++)
            {
                buffer[(y * width) + x] = blank;
            }
        }

        WriteConsoleOutput(
            handle,
            buffer,
            new Coordinate { X = width, Y = height },
            new Coordinate { X = 0, Y = 0 },
            ref targetRegion);
    }

    // http://pinvoke.net/default.aspx/kernel32/WriteConsoleOutput.html
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    internal static extern bool WriteConsoleOutput(
        IntPtr consoleOutput,
        CharInfo[] buffer,
        Coordinate bufferSize,
        Coordinate bufferCoord,
        ref Rectangle targetRegion);

    // http://pinvoke.net/default.aspx/kernel32/ReadConsoleOutput.html
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    internal static extern bool ReadConsoleOutput(
        IntPtr hConsoleOutput,
        [Out] CharInfo[] lpBuffer,
        Coordinate dwBufferSize,
        Coordinate dwBufferCoord,
        ref Rectangle lpReadRegion);

    [DllImport("kernel32.dll", SetLastError = true)]
    internal static extern IntPtr GetStdHandle(Channel channel);

    // https://pinvoke.net/default.aspx/kernel32/ConsoleFunctions.html
    [StructLayout(LayoutKind.Sequential)]
    public struct Coordinate
    {
        public short X;

        public short Y;
    }

    // https://pinvoke.net/default.aspx/kernel32/ConsoleFunctions.html
    public struct Rectangle
    {
        public short Left;

        public short Top;

        public short Right;

        public short Bottom;
    }

    // https://pinvoke.net/default.aspx/kernel32/ConsoleFunctions.html
    // CHAR_INFO struct, which was a union in the old days
    // so we want to use LayoutKind.Explicit to mimic it as closely
    // as we can
    [StructLayout(LayoutKind.Explicit)]
    public struct CharInfo
    {
        [FieldOffset(0)]
        public char UnicodeChar;

        [FieldOffset(0)]
        public char AsciiChar;

        // https://docs.microsoft.com/de-de/windows/console/char-info-str
        // 2 bytes seems to work properly
        [FieldOffset(2)]
        public ushort Attributes;

        [FieldOffset(0)]
        internal byte FirstByte;

        [FieldOffset(1)]
        internal byte SecondByte;
    }
}
"@


class ConsoleDisplay {
        [int] $width;

        hidden [int] $height;

        hidden [NativeConsole+CharInfo[]] $buffer;

        hidden [NativeConsole+CharInfo] $space = [ConsoleDisplay]::GetCharInfo(' ');

        hidden [NativeConsole+CharInfo[]] $originalDisplayContent;

        hidden [NativeConsole+Coordinate] $size;

        hidden [NativeConsole+Coordinate] $location;

        hidden [bool] $originalIsCursorShown = $true;

        hidden [System.Timers.Timer] $flushTimer;

        hidden [bool] $hasChanges = $false;

        static [NativeConsole+CharInfo] GetCharInfo([char] $character) {
            $result = [NativeConsole+CharInfo]::new() 
            $result.UnicodeChar = character
            $result.Attributes = 0x0000
            return $result
        }
}

function Build-CellArray {
    [OutputType([System.Management.Automation.Host.BufferCell[, ]])]
    param([string[]] $Body, [System.ConsoleColor] $ForegroundColor = [System.ConsoleColor]::Black, [System.ConsoleColor] $BackgroundColor = [System.ConsoleColor]::White)
    Write-Host "Stuff: $($Body.GetType())"
    $Host.UI.RawUI.NewBufferCellArray([string[]]$Body, $ForegroundColor, $BackgroundColor)
}
# $bca = Build-CellArray @("moi morn", "du   des")
# $bca.GetLength(1)

function Show-Window {
    # https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.ConsoleHost/host/msh/ProgressPane.cs
    param([string] $message, [switch]$noPadding)

    $rawUi = $Host.UI.RawUI
    $bufferSize = $rawUi.BufferSize

    # https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshostrawuserinterface.newbuffercellarray?view=powershellsdk-7.0.0

    [string[]] $message = if ($noPadding) { 
        ,$message
     } else {
        "  " + $message + "  ", "  " + $message + "  ", "  " + $message + "  "
    } 

    # https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshostrawuserinterface.newbuffercellarray?view=powershellsdk-7.0.0
    $bufferCellArray = Build-CellArray $message [ConsoleColor]::Black [ConsoleColor]::White

    $rows = $bufferCellArray.GetLength(0);
    $cols = $bufferCellArray.GetLength(1);

    # centered box
    $x = [int](($bufferSize.Width / 2) - ($cols / 2))
    $y = [int](($bufferSize.Height / 2) - ($rows / 2))

    $location = [System.Management.Automation.Host.Coordinates]::new($x,$y)

    #$location = $rawUi.WindowPosition
    $savedCursor = $rawUi.CursorPosition;
    
    #$location.X = 0;
    #$location.Y = [Math]::Min($location.Y + 2, $bufferSize.Height);

    $savedRegion = $rawUi.GetBufferContents(
        [System.Management.Automation.Host.Rectangle]::new(
            $location.X, 
            $location.Y, 
            $location.X + $cols - 1, 
            $location.Y + $rows - 1
        )
    )

    $rawUi.SetBufferContents($location, $bufferCellArray)

    Start-Sleep -Seconds 5

    $rawUi.SetBufferContents($location, $savedRegion)

    $rawUi.CursorPosition = $savedCursor

}
#Show-Window "this is a test"
