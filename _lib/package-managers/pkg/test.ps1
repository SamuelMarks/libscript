<#
.SYNOPSIS
Test suite for the pkg component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& pkg --version
