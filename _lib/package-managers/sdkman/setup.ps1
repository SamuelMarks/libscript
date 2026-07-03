<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'sdkman' stack.

.DESCRIPTION
Execute this script to install and configure sdkman on the local system.
#>

$ErrorActionPreference = "Stop"

Write-Host "SDKMAN is not supported natively on Windows (Requires WSL, Cygwin, MSYS, or Git Bash)."
exit 1
