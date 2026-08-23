<#
.SYNOPSIS
Test suite for the xbps component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& xbps --version
