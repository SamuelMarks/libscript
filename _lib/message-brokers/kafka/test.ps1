<#
.SYNOPSIS
Test suite for the kafka component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& kafka --version
