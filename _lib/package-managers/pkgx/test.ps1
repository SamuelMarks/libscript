<#
.SYNOPSIS
Test suite for the pkgx component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& pkgx --version
