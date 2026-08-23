<#
.SYNOPSIS
Test suite for the maven component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

mvn --version
