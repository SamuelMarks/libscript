<#
.SYNOPSIS
Test suite for the mamba component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& mamba --version
