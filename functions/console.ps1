function Build-CellArray {
    [OutputType([System.Management.Automation.Host.BufferCell[, ]])]
    param([string[]] $Body, [System.ConsoleColor] $ForegroundColor = [System.ConsoleColor]::Black, [System.ConsoleColor] $BackgroundColor = [System.ConsoleColor]::White)
    Write-Host "Stuff: $($Body.GetType())"
    $Host.UI.RawUI.NewBufferCellArray([string[]]$Body, $ForegroundColor, $BackgroundColor)
}
$bca = Build-CellArray @("moi morn", "du   des")
$bca.GetLength(1)

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
