<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for rust.
#>

$ErrorActionPreference = "Stop"

$RustVersion = $env:RUST_VERSION
if ([string]::IsNullOrEmpty($RustVersion)) {
    $RustVersion = "stable"
}
if ($RustVersion -eq "latest") {
    $RustVersion = "stable"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$RustDir = Join-Path $LibscriptHome "rust\$RustVersion"
$RustBinPath = Join-Path $RustDir "bin"
if (-not ($env:PATH -split ';' -contains $RustBinPath)) {
    $env:PATH = "$RustBinPath;" + $env:PATH
}