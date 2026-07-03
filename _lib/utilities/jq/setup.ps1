<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'jq' stack.

.DESCRIPTION
Execute this script to install and configure jq on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
# winget install --silent --force --id=astral-sh.uv  -e

winget install --silent --force jqlang.jq
