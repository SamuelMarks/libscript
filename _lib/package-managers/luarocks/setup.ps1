<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'luarocks' stack.

.DESCRIPTION
Execute this script to install and configure luarocks on the local system.
#>

$ErrorActionPreference = "Stop"

Write-Host "luarocks requires a compiled Lua installation and C toolchain on Windows, use a system package manager (e.g. MSYS2/winget)."
exit 1
