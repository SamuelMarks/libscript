# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the JupyterHub data science platform stack.

.DESCRIPTION
Execute this script to install and configure jupyterhub on the local system.
#>

$ErrorActionPreference = "Stop"

pip install jupyterhub
npm install -g configurable-http-proxy
