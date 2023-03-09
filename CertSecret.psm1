[CmdletBinding]

##### Variables #############################################

$InformationPreference = "Continue"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

[string]$script:scriptPath = Split-Path (get-variable myinvocation -scope script).value.Mycommand.Definition -Parent
$currentModuleName = Split-Path -path $script:ScriptPath -Leaf -Resolve
Write-Debug -Message "ScriptPath : $script:scriptPath"
Write-Debug -Message "ModuleName : $currentModuleName"

##### Functions #############################################

# no functions

##### Main ##################################################

# Load and export methods
Write-Information -Message "Importing $currentModuleName module. Exporting functions. This may take a moment or two."
# Dot sourcing public function files
Get-ChildItem $script:ScriptPath/public -Recurse -Filter "*.ps1" -File | ForEach-Object { 
    . $_.FullName

    # Find all the functions defined no deeper than the first level deep and export it.
    # This looks ugly but allows us to not keep any un-needed variables from poluting the module.
    ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
        Export-ModuleMember $_.Name
    }
}
