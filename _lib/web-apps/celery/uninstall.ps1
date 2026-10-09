# ## Overview
# PowerShell script for uninstall.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles the removal and uninstallation process for the Celery task queue stack.

.DESCRIPTION
Execute this script to remove celery and its associated configurations from the system.
#>

$ErrorActionPreference = "Stop"

Write-Output "./stacks/task-queues/celery uninstall skipped"
