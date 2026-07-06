<#
.SYNOPSIS
Internal script for busybox on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for busybox.
#>

# Windows PowerShell env stub for busybox

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:BUSYBOX_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "busybox") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
