namespace ConDraw;

using System;
using System.Threading;
using static NativeConsole;

public class ConsoleDisplay : IDisposable
{
    private readonly int width;

    private readonly int height;

    private readonly CharInfo[] buffer;

    private readonly CharInfo space = GetCharInfo(' ');

    private readonly CharInfo[] originalDisplayContent;

    private readonly Coordinate size;

    private readonly Coordinate location;

    private readonly bool originalIsCursorShown = true;

    private readonly Timer flushTimer;

    private bool hasChanges = false;

    public ConsoleDisplay()
        : this(Console.WindowWidth, Console.WindowHeight)
    {
    }

    public ConsoleDisplay(int width, int height)
    {
        this.width = width;
        this.height = height;

        this.buffer = new CharInfo[height * width];

        this.Clear();

        this.size = new Coordinate { X = (short)this.width, Y = (short)this.height };
        this.location = new Coordinate { X = 0, Y = 0 };

        this.originalDisplayContent = new CharInfo[height * width];

        var outputHandle = Native.NativeConsole.GetStdHandle(Channel.StdOutput);
        var region = this.GetRegion();

        Native.NativeConsole.ReadConsoleOutput(
            outputHandle,
            this.originalDisplayContent,
            this.size,
            this.location,
            ref region);

        if (OperatingSystem.IsWindows())
        {
            this.originalIsCursorShown = Console.CursorVisible;
        }

        Console.CursorVisible = false;
        this.Flush();

        // every 40 ms == 25 frames / second
        this.flushTimer = new Timer((state) => this.Flush(), this, 40, 40);
    }

    ~ConsoleDisplay()
    {
        this.Dispose();
    }

    public static CharInfo GetCharInfo(char character)
        => new()
        {
            UnicodeChar = character,
            Attributes = 0x0000,
        };

    public void Set(int x, int y, char character)
        => this.Set(x, y, GetCharInfo(character));

    public void Set(int x, int y, CharInfo character)
    {
        if (x >= this.width || y >= this.height)
        {
            return;
        }

        this.hasChanges = true;
        this.buffer[(y * this.width) + x] = character;
    }

    public void DrawFrame(int startX, int startY, int width, int height, bool half = true)
    {
        // "█▀▄ ▛▜▙▟"
        var endX = startX + width;
        var endY = startY + height;

        var sideChar = '█';
        var topChar = half ? '▀' : sideChar;
        var bottomChar = half ? '▄' : sideChar;

        for (int y = startY; y < endY; y++)
        {
            this.Set(startX, y, sideChar);
            this.Set(endX - 1, y, sideChar);
        }

        for (int x = startX + 1; x < endX - 1; x++)
        {
            this.Set(x, startY, topChar);
            this.Set(x, endY - 1, bottomChar);
        }
    }

    //// public void DrawPixelFrame(int startX, int startY, int width, int height)
    //// {
    ////     // A        B        C
    ////     // 0,0,5,4  0,1,5,3  0,1,5,4
    ////     // █▀▀▀█    ▄▄▄▄▄    ▄▄▄▄▄
    ////     // █▄▄▄█    █▄▄▄█    █   █
    ////     //                   ▀▀▀▀▀
    ////     //
    ////     // "█▀▄ ▛▜▙▟"

    ////     var startLow = startY % 2 > 0;
    ////     var endHigh = startY + height % 2 > 0;

    ////     var endX = startX + width;
    ////     var endY = startY + height;

    ////     for (int y = startY; y < endY; y++)
    ////     {
    ////         this.Set(startX, y, '█');
    ////         this.Set(endX - 1, y, '█');
    ////     }

    ////     for (int x = startX + 1; x < endX - 1; x++)
    ////     {
    ////         this.Set(x, startY, '▀');
    ////         this.Set(x, endY - 1, '▄');
    ////     }
    //// }

    public void Clear()
    {
        Array.Fill(this.buffer, this.space);
        this.hasChanges = true;
    }

    public void Dispose()
    {
        GC.SuppressFinalize(this);

        this.flushTimer.Dispose();

        this.FlushBuffer(this.originalDisplayContent);
        Console.CursorVisible = this.originalIsCursorShown;
    }

    private void Flush()
    {
        if (this.hasChanges)
        {
            this.FlushBuffer(this.buffer);
            this.hasChanges = false;
        }
    }

    private void FlushBuffer(CharInfo[] buffer)
    {
        var handle = GetStdHandle(Channel.StdOutput);
        var region = this.GetRegion();

        WriteConsoleOutput(
            handle,
            buffer,
            this.size,
            this.location,
            ref region);
    }

    private Rectangle GetRegion()
        => new()
        {
            Top = 0,
            Left = 0,
            Bottom = (short)this.height,
            Right = (short)this.width,
        };
}
