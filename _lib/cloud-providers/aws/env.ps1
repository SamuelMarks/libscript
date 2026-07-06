<#
.SYNOPSIS
Internal script for aws on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for aws.
#>

# Windows PowerShell env stub for aws

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:AWS_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "aws") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
