<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'brew' stack.

.DESCRIPTION
Execute this script to install and configure brew on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

Write-Host "brew is not supported natively on Windows (unless via WSL, which uses Linux scripts)."
