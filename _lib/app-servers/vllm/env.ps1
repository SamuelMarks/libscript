<#
.SYNOPSIS
Internal script for vllm on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for vllm.
#>

# Windows PowerShell env stub for vllm

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:VLLM_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "vllm") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
