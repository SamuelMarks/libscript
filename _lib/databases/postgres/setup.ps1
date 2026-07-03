<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'postgres' stack.

.DESCRIPTION
Execute this script to install and configure postgres on the local system.
#>

$ErrorActionPreference = "Stop"

winget install --silent --force --id=PostgreSQL.PostgreSQL -e --accept-package-agreements --accept-source-agreements
