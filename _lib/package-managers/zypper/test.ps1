<#
.SYNOPSIS
Test suite for the zypper component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& zypper --version
