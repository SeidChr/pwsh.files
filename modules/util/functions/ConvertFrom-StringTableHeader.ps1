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

param(
    [int[]]$ColumnSizes
)

process {
    # $_;
    $len = $_.length;
    if ($ColumnSizes) {
        $pos = 0;
        $matchList = for ($i = 0; $i -lt $ColumnSizes.Count; $i++) {
            if ($pos -ge $len) {
                break
            }

            $size = $ColumnSizes[$i]

            if (($pos + $size) -gt $len) {
                $size = $len - $pos
            }

            [PsCustomObject]@{
                Index = $pos
                Value = $_.Substring($pos, $size)
            }

            $pos += $size;
        }
    } else {
        $matchList = [regex]::Matches($_, "(?<=^\s*|\S\s{2,})[^\s].*?(?=\s{2}|\s*$)") | Select-Object Index, Value
    }

    $indexMatchOffset = 0;
    if ($matchList[0].Index -gt 0) {
        $indexMatchOffset++

        [PsCustomObject]@{
            Label  = "0"
            Index  = 0
            Start  = 0
            Length = $matchList[0].Index
        }
    }

    for ($i = 0; $i -lt ($matchList.Count - 1); $i++) {
        $start = $matchList[$i].Index
        $length = $matchList[$i + 1].Index - $start
        $label = if ($matchList[$i].Value) { 
            $matchList[$i].Value
        } else {
            $i
        }

        [PsCustomObject]@{
            Label  = $label
            Index  = $i + $indexMatchOffset
            Start  = $start
            Length = $length
        }
    }

    $lastIndex = $matchList.Count - 1
    $lastMatch = $matchList[$lastIndex];

    [PsCustomObject]@{
        Label  = $lastMatch.Value
        Index  = $lastIndex + $indexMatchOffset
        Start  = $lastMatch.Index
        Length = $len - $lastMatch.Index
    }
}