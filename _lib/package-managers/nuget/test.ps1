<#
.SYNOPSIS
Test suite for the nuget component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& nuget --version
