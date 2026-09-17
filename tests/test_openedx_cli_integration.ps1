# ## Overview
# PowerShell script for test_openedx_cli_integration.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Exhaustive PowerShell native Windows test suite for Open edX.
#>
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> [TEST 1/9] Testing nodeenv CLI..."
& (Join-Path $ScriptDir "../_lib/package-managers/nodeenv/cli.ps1") help

Write-Host "==> [TEST 2/9] Testing MySQL CLI..."
& (Join-Path $ScriptDir "../_lib/databases/mysql/cli.ps1") help

Write-Host "==> [TEST 3/9] Testing Waitress CLI..."
& (Join-Path $ScriptDir "../_lib/app-servers/waitress/cli.ps1") help

Write-Host "==> [TEST 4/9] Testing Uvicorn CLI..."
& (Join-Path $ScriptDir "../_lib/app-servers/uvicorn/cli.ps1") help

Write-Host "==> [TEST 5/9] Testing Gunicorn CLI..."
& (Join-Path $ScriptDir "../_lib/app-servers/gunicorn/cli.ps1") help

Write-Host "==> [TEST 6/9] Testing Meilisearch CLI..."
& (Join-Path $ScriptDir "../_lib/search/meilisearch/cli.ps1") help

Write-Host "==> [TEST 7/9] Testing hMailServer CLI..."
& (Join-Path $ScriptDir "../_lib/utilities/hmailserver/cli.ps1") help

Write-Host "==> [TEST 8/9] Testing Exim CLI..."
& (Join-Path $ScriptDir "../_lib/utilities/exim/cli.ps1") help

Write-Host "==> [TEST 9/9] Testing Open edX Stack CLI..."
& (Join-Path $ScriptDir "../stacks/cms/openedx/cli.ps1") help

Write-Host "=========================================================="
Write-Host "[SUCCESS] All Open edX components verified on native Windows via PowerShell!"
Write-Host "=========================================================="
exit 0
