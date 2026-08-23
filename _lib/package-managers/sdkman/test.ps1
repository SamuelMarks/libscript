<#
.SYNOPSIS
Test suite for the sdkman component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& sdkman --version
