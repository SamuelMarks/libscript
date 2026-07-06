<#
.SYNOPSIS
Internal script for duckdb on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for duckdb.
#>

# Windows PowerShell env stub for duckdb

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$CompVersion = $env:DUCKDB_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) {
    $CompVersion = "latest"
}

$TargetBin = Join-Path (Join-Path (Join-Path $LibscriptHome "duckdb") $CompVersion) "bin"
$env:PATH = "$TargetBin;$env:PATH"
