# ## Overview
# PowerShell script for test.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Test suite for the npm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& npm --version
