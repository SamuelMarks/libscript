<#
.SYNOPSIS
Test suite for the poetry component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& poetry --version
