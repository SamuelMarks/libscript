# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    End-to-end integration test runner for Open edX on Windows PowerShell.
#>
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==> Executing Open edX End-to-End Registration and Login Verification on Windows PowerShell..."
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    & python (Join-Path $ScriptDir "test_harness.py")
    exit $LASTEXITCODE
} elseif (Get-Command "py" -ErrorAction SilentlyContinue) {
    & py (Join-Path $ScriptDir "test_harness.py")
    exit $LASTEXITCODE
} else {
    Write-Error "Python runtime required for Open edX end-to-end verification."
    exit 1
}
