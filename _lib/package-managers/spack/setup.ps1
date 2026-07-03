<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'spack' stack.

.DESCRIPTION
Execute this script to install and configure spack on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command spack -ErrorAction SilentlyContinue)) {
  Write-Host "Spack natively supports Windows but recommends building via GitHub clone and Visual Studio toolchain."
  Write-Host "It is too complex to automated safely here. Please follow https://spack.readthedocs.io/en/latest/getting_started.html"
  exit 1
}
