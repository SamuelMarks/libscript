<#
.SYNOPSIS
Test suite for the msys2 component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& msys2 --version
