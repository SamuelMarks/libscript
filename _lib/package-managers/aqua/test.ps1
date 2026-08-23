<#
.SYNOPSIS
Test suite for the aqua component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& aqua --version
