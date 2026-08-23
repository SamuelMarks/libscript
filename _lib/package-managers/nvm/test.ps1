<#
.SYNOPSIS
Test suite for the nvm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& nvm --version
