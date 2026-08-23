<#
.SYNOPSIS
Test suite for the kotlin component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& kotlin --version
