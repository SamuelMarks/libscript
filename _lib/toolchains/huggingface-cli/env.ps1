<#
.SYNOPSIS
Internal script for huggingface-cli on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for huggingface-cli.
#>

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$HfCliDir = Join-Path $LibscriptHome "huggingface-cli\$env:HUGGINGFACE_CLI_VERSION"
$env:PATH = "$(Join-Path $HfCliDir 'bin');" + $env:PATH
if ([string]::IsNullOrEmpty($env:PYTHONPATH)) {
    $env:PYTHONPATH = $HfCliDir
} else {
    $env:PYTHONPATH = "$HfCliDir;" + $env:PYTHONPATH
}
