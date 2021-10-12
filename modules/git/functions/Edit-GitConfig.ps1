param([switch] $Global)

$Path = if ($Global) {
    Join-Path "~" ".gitconfig"
} else {
    Join-Path "." ".git" "config"
}

code $Path

