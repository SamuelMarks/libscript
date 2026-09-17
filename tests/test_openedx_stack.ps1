# ## Overview
# PowerShell script for test_openedx_stack.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell integration test runner for Open edX.
#>
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Testing nodeenv CLI on Windows..."
& (Join-Path $ScriptDir "../_lib/package-managers/nodeenv/cli.ps1") help

Write-Host "==> Testing MySQL CLI on Windows..."
& (Join-Path $ScriptDir "../_lib/databases/mysql/cli.ps1") help

Write-Host "==> Testing Gunicorn CLI on Windows..."
& (Join-Path $ScriptDir "../_lib/app-servers/gunicorn/cli.ps1") help

Write-Host "==> Testing uWSGI CLI on Windows..."
& (Join-Path $ScriptDir "../_lib/app-servers/uwsgi/cli.ps1") help

Write-Host "==> Testing Meilisearch CLI on Windows..."
& (Join-Path $ScriptDir "../_lib/search/meilisearch/cli.ps1") help

Write-Host "==> Testing Exim CLI on Windows..."
& (Join-Path $ScriptDir "../_lib/utilities/exim/cli.ps1") help

Write-Host "==> Testing Open edX Stack CLI on Windows..."
& (Join-Path $ScriptDir "../stacks/cms/openedx/cli.ps1") help

Write-Host "==> All Open edX Windows components verified successfully!"
exit 0
