<#
.SYNOPSIS
Test suite for the yarn component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& yarn --version
