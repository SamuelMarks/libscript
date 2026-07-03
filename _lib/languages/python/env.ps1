<#
.SYNOPSIS
Defines environment variables and configurations for the environment variables stack.

.DESCRIPTION
Source or call this script to configure the environment for python.
#>

$ErrorActionPreference = "Stop"

$PythonVersion = $env:PYTHON_VERSION
if ([string]::IsNullOrEmpty($PythonVersion)) {
    $PythonVersion = "3.11.9"
}
$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $HOME ".libscript"
}
$PyPath = Join-Path $LibscriptHome "python\$PythonVersion"
$PyScriptsPath = Join-Path $PyPath "Scripts"
if (-not ($env:PATH -split ';' -contains $PyScriptsPath)) {
    $env:PATH = "$PyScriptsPath;" + $env:PATH
}
if (-not ($env:PATH -split ';' -contains $PyPath)) {
    $env:PATH = "$PyPath;" + $env:PATH
}

if (-not [string]::IsNullOrEmpty($env:PYTHON_VENV)) {
    $VenvPath = Join-Path $env:PYTHON_VENV "Scripts"
    if (-not ($env:PATH -split ';' -contains $VenvPath)) {
        $env:PATH = "$VenvPath;" + $env:PATH
    }
    $env:VIRTUAL_ENV = $env:PYTHON_VENV
}