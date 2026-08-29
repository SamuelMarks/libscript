# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

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
$env:PYTHONHOME = Join-Path $LibscriptHome "python\$PythonVersion"
$PyPath = Join-Path $env:PYTHONHOME "bin"
$PyScriptsPath = Join-Path $env:PYTHONHOME "Scripts"

# In Windows, site-packages are under Lib\site-packages
$SitePackages = Join-Path $env:PYTHONHOME "Lib\site-packages"
if ([string]::IsNullOrEmpty($env:PYTHONPATH)) {
    $env:PYTHONPATH = $SitePackages
} else {
    $env:PYTHONPATH = "$SitePackages;" + $env:PYTHONPATH
}

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
    Remove-Item Env:\PYTHONHOME -ErrorAction SilentlyContinue
}