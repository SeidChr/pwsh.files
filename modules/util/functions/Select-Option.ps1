# .Synopsis
# https://social.technet.microsoft.com/wiki/contents/articles/24030.powershell-demo-prompt-for-choice.aspx
# Select-Option "Programm Extermination" "Quit Or Go On?" "&Continue","&Exterminate" 0
param(
    [string] $Caption,
    [string] $Message,
    [string[]] $Choices,
    [int] $Default = 0
)

$Selection = $Choices | ForEach-Object { New-Object System.Management.Automation.Host.ChoiceDescription $_ }
$Host.UI.PromptForChoice($Caption, $Message, $Selection, $Default)
