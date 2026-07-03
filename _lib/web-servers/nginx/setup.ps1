<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'nginx' stack.

.DESCRIPTION
Execute this script to install and configure nginx on the local system.
#>

$ErrorActionPreference = "Stop"

winget install --silent --force --id=Nginx.Nginx -e --accept-package-agreements --accept-source-agreements
