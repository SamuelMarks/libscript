<#
.SYNOPSIS
Test suite for the cpanm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& cpanm --version
