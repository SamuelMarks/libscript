<#
.SYNOPSIS
Test suite for the kubernetes component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& kubernetes --version
