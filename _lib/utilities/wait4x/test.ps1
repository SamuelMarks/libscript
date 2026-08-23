<#
.SYNOPSIS
Test suite for the wait4x component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& wait4x --version
