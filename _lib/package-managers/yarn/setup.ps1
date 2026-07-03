<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'yarn' stack.

.DESCRIPTION
Execute this script to install and configure yarn on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command yarn -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\npm\setup.ps1"
  npm install -g yarn
}
