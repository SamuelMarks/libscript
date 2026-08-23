<#
.SYNOPSIS
Test suite for the xpk component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

xpk --version
