<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'pnpm' stack.

.DESCRIPTION
Execute this script to install and configure pnpm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\npm\setup.ps1"
  npm install -g pnpm
}
