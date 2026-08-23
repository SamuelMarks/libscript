<#
.SYNOPSIS
Test suite for the nginx component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& nginx --version
