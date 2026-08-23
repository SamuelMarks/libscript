<#
.SYNOPSIS
Test suite for the cargo component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& cargo --version
