<#
.SYNOPSIS
Test suite for the psmux component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& psmux --version
