<#
.SYNOPSIS
Test suite for the pacman component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& pacman --version
