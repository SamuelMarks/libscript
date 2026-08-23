<#
.SYNOPSIS
Test suite for the 7zip component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& 7zip --version
