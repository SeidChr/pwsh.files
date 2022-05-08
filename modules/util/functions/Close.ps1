# .Synopsis
# avoids changes on a variable to propagate into closures
# https://github.com/PowerShell/PowerShell/blob/91e7298fd8101b85b17514dfefa41b20a7276ca4/src/System.Management.Automation/engine/Modules/PSModuleInfo.cs#L1340
# https://github.com/PowerShell/PowerShell/blob/91e7298fd8101b85b17514dfefa41b20a7276ca4/src/System.Management.Automation/engine/lang/scriptblock.cs#L119

param(
    [Parameter(ValueFromRemainingArguments, Position = 0)]
    [Alias("Variables", "Args", "Arguments", "Var", "Vars", "On")]
    [string[]] $VariableNames,
    [Parameter(ValueFromPipeline, Mandatory, Position = 1)]
    [scriptblock] $Script
)

$module = [psmoduleinfo]::new($true)

$VariableNames | ForEach-Object {
    $module.SessionState.PSVariable.Set($_, $(Get-Variable -Name $_).Value)
}

$module.NewBoundScriptBlock($s)
