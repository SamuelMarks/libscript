<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'nuget' stack.

.DESCRIPTION
Execute this script to install and configure nuget on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command nuget -ErrorAction SilentlyContinue)) {
  Write-Host "nuget not found. Please install the .NET SDK, or nuget via chocolatey/winget."
}
