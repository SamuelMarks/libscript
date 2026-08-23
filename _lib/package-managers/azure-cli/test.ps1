<#
.SYNOPSIS
Test suite for the azure-cli component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& az --version
