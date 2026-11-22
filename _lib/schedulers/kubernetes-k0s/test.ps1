# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the kubernetes-k0s component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& kubernetes-k0s --version
