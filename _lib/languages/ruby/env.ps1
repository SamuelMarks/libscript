<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for ruby.
#>

$ErrorActionPreference = "Stop"

$RubyVersion = $env:RUBY_VERSION
if ([string]::IsNullOrEmpty($RubyVersion)) {
    $RubyVersion = "latest"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$RubyPath = Join-Path $LibscriptHome "ruby\$RubyVersion\bin"
if (-not ($env:PATH -split ';' -contains $RubyPath)) {
    $env:PATH = "$RubyPath;" + $env:PATH
}