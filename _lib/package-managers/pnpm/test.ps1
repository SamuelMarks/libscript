<#
.SYNOPSIS
Test suite for the pnpm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& pnpm --version
