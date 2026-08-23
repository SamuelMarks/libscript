<#
.SYNOPSIS
Test suite for the aria2 component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& aria2 --version
