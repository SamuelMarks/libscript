<#
.SYNOPSIS
Test suite for the openrc component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& openrc --version
