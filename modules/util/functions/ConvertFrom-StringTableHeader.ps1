# .SYNOPSIS
# .EXAMPLE
# " SITZUNGSNAME      BENUTZERNAME             ID  STATUS  TYP         GER�T" | ConvertFrom-StringTableHeader
# Label        Start Length
# -----        ----- ------
#                  0      1
# SITZUNGSNAME     1     18
# BENUTZERNAME    19     25
# ID              44      4
# STATUS          48      8
# GER�T           68      6

process {
    # $_;
    $len = $_.length;
    $matchList = [regex]::Matches($_, "(?<=[\s^])[^\s]+")

    if ($matchList[0].Index -gt 0) {
        [PsCustomObject]@{
            Label  = "0"
            Start  = 0
            Length = $matchList[0].Index
        }
    }

    for ($i = 0; $i -lt ($matchList.Count - 2); $i++) {
        $start = $matchList[$i].Index
        $length = $matchList[$i + 1].Index - $start
        [PsCustomObject]@{
            Label  = if ($matchList[$i].Value) { $matchList[$i].Value } else { $i }
            Start  = $start
            Length = $length
        }
    }

    $lastMatch = $matchList[$matchList.Count - 1];
    [PsCustomObject]@{
        Label  = $lastMatch.Value
        Start  = $lastMatch.Index
        Length = $len - $lastMatch.Index
    }
}