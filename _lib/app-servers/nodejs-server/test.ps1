<#
.SYNOPSIS
Test suite for the nodejs-server component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& nodejs-server --version
