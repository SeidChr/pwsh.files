param(
    [int]      $DelaySeconds = 10,
    [int]      $TimeoutSeconds = 1,
    [string[]] $Target,
    [int]      $historySize = 300,
    [switch]   $Debug,
    [string]   $FileName
)

$format = "yyyy-MM-dd HH:mm:ss"
$history = [boolean[]]::new($historySize)

filter Debug {
    param($name)
    if ($debug) {
        Write-Host "[DEBUG] $($name): $_"
    }
}

filter AddToHistory {
    $size = $historySize
    for ($i = 0; $i -lt ($size - 1); $i++) {
        $history[$i] = $history[$i + 1]
    }

    $history[$size - 1] = $_
}

function AnyInHistory {
    $size = $historySize
    for ($i = 0; $i -lt $size; $i++) {
        if ($history[$i]) { 
            return $true 
        }
    }
    return $false
}

function Log {
    param([string] $Message) 
    if ($FileName) {
        $Message >> $FileName
    }
}

function DebugHistory {
    if ( ! $Debug ) {
        return
    }

    $size = $historySize
    Write-Host "[DEBUG] History: " -NoNewline

    for ($i = 0; $i -lt $size; $i++) {
        Write-Host ($history[$i] ? "True" : "False") "" -NoNewline
    }

    Write-Host
}

Log -Message "[DELAY=$DelaySeconds TIMEOUT=$TimeoutSeconds HISTORY=$historySize START='$(Get-Date -Format:$format)']"

$last = $false

Test-Connection -Delay $DelaySeconds -TargetName $Target -TimeoutSeconds $TimeoutSeconds -Repeat | ForEach-Object {
    $lastShort = $_.Status -eq 0
    $lastShort | Debug "LastShort"
    $lastShort | AddToHistory
    DebugHistory
    $status = AnyInHistory
    $status | Debug "Status"
    $last | Debug "Last"
    if ($status -ne $last) {
        $last = $status
        $now = Get-Date
        $nowFormatted = $now.ToString($format)

        $then = $now.AddSeconds( - ($historySize * $DelaySeconds) )
        $thenFormatted = $then.ToString($format)

        if ($status) {
            Log -Message "$nowFormatted ON"
            Write-Host ($nowFormatted | Add-Color "555" -BgColor "0f0")
        } else {
            Log -Message "$thenFormatted OFF (detected $nowFormatted)"
            Write-Host ("$thenFormatted ($nowFormatted)" | Add-Color "ff0" -BgColor "f00")
        }
    }

    $nullPos = $Host.UI.RawUI.CursorPosition

    if ($lastShort) {
        Write-Host ("currently  ON" | Add-Color "555" -BgColor "0c0") -NoNewline
    } else {
        Write-Host ("currently OFF" | Add-Color "ff0" -BgColor "c00") -NoNewline
    }

    $Host.UI.RawUI.CursorPosition = $nullPos # reset x to overwrite with actual status change
}