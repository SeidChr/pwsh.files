# .SYNOPSIS
# .EXAMPLE
# query session | ConvertFrom-StringTable | ft
# BENUTZERNAME  ID SITZUNGSNAME     0 GERAET STATUS
# ------------  -- ------------     - ------ ------
#               0  services                  Getr. 
# Prinz Albert  4  console          >        Aktiv 
# 655           36 31c5ce94259d4...          Abhör.

begin {
    $lineNr = 0;
}

process {
    if ($lineNr -eq 0) {
        $columns = $_ | ConvertFrom-StringTableHeader
    } elseif ($columns) {
        [string]$line = $_
        $result = @{}

        foreach ($column in $columns) {
            $result[$column.Label.Trim()] = $line.Substring($column.Start, $column.Length).Trim()
        }

        [pscustomobject]$result
    } else {
        $_
    }

    $lineNr++
}
