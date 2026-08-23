<#
.SYNOPSIS
Test suite for the vcpkg component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& vcpkg --version
