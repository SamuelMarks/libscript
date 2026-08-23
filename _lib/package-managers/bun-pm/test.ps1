<#
.SYNOPSIS
Test suite for the bun-pm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& bun --version
