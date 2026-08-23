<#
.SYNOPSIS
Test suite for the pdm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& pdm --version
