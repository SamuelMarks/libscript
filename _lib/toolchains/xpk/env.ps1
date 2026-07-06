<#
.SYNOPSIS
Internal script for xpk on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for xpk.
#>

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$XpkDir = Join-Path $LibscriptHome "xpk\$env:XPK_VERSION"
$env:PATH = "$(Join-Path $XpkDir 'bin');" + $env:PATH
if ([string]::IsNullOrEmpty($env:PYTHONPATH)) {
    $env:PYTHONPATH = $XpkDir
} else {
    $env:PYTHONPATH = "$XpkDir;" + $env:PYTHONPATH
}
