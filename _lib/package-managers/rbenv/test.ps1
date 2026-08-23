<#
.SYNOPSIS
Test suite for the rbenv component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& rbenv --version
