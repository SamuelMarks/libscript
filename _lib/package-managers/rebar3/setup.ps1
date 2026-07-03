<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rebar3' stack.

.DESCRIPTION
Execute this script to install and configure rebar3 on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command rebar3 -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
