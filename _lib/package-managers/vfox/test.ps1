<#
.SYNOPSIS
Test suite for the vfox component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& vfox --version
