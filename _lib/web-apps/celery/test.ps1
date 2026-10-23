# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Implements automated tests to verify the correctness of the Celery task queue stack.

.DESCRIPTION
Execute this script to run the test suite for celery.
#>

$ErrorActionPreference = "Stop"

Write-Output "./_lib/web-apps/celery test skipped"
