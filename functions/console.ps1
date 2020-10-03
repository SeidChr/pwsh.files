function Show-Window {
    $rawUi = $Host.UI.RawUI
    $bufferSize = $rawUi.BufferSize
    $fg = $host.UI.RawUI.ForegroundColor
    $bg = $host.UI.RawUI.BackgroundColor
    $bufferCellArray = $rawUi.NewBufferCellArray(
        "This is a Test", 
        [ConsoleColor]::Black, 
        [ConsoleColor]::White
    )

    $rows = $bufferCellArray.GetLength(0);
    $cols = $bufferCellArray.GetLength(1);
    # $coordinates = [System.Management.Automation.Host.Coordinates]::new(0,0)

    $location = $rawUi.WindowPosition
    $savedCursor = $rawUi.CursorPosition;
    
    $location.X = 0;
    $location.Y = [Math]::Min($location.Y + 2, $bufferSize.Height);

    $savedRegion = $rawUi.GetBufferContents(
        [System.Management.Automation.Host.Rectangle]::new(
            $location.X, 
            $location.Y, 
            $location.X + $cols - 1, 
            $location.Y + $rows - 1
        )
    )

    $rawUi.SetBufferContents($location, $bufferCellArray);
}
# Show-Window
