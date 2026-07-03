<#
.SYNOPSIS
Handles the removal and uninstallation process for the component 'etcd' stack.

.DESCRIPTION
Execute this script to remove etcd and its associated configurations from the system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh
Write-Host "Uninstalling etcd..."
choco uninstall -y etcd
