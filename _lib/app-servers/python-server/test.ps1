<#
.SYNOPSIS
Test suite for the python-server component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& python-server --version
