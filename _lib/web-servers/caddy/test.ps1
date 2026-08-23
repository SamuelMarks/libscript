<#
.SYNOPSIS
Test suite for the caddy component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& caddy --version
