<#
.SYNOPSIS
Test suite for the cpp component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

gcc --version
