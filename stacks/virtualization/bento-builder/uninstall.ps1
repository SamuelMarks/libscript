# ## Overview
# PowerShell uninstallation script for Bento Builder stack.

$ErrorActionPreference = "Stop"

$LibscriptRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
& (Join-Path $LibscriptRoot "_lib\orchestration\qemu\uninstall.ps1")
& (Join-Path $LibscriptRoot "_lib\orchestration\virtualbox\uninstall.ps1")
& (Join-Path $LibscriptRoot "_lib\orchestration\packer\uninstall.ps1")
& (Join-Path $LibscriptRoot "_lib\orchestration\vagrant\uninstall.ps1")
