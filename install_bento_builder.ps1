# ## Overview
# Standalone PowerShell script to provision the Bento Builder environment on Windows.

<#
.SYNOPSIS
Installs QEMU, VirtualBox, Packer, Vagrant, and supporting build tools for Bento.
#>

$ErrorActionPreference = "Stop"

Write-Output "===================================================="
Write-Output " Bento Builder Environment Installer (PowerShell)"
Write-Output "===================================================="

& (Join-Path $PSScriptRoot "stacks\virtualization\bento-builder\setup.ps1")
Write-Output "Installation complete! Running validation tests..."
& (Join-Path $PSScriptRoot "stacks\virtualization\bento-builder\test.ps1")
