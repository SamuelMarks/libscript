# ## Overview
# PowerShell script for setup.ps1 for Bento Builder stack.

$ErrorActionPreference = "Stop"

$SetupGeneric = Join-Path $PSScriptRoot "setup_generic.ps1"
if (Test-Path $SetupGeneric) {
    & $SetupGeneric @args
}
