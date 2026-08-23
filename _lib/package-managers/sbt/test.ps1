<#
.SYNOPSIS
Test suite for the sbt component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& sbt --version
