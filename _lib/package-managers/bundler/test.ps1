<#
.SYNOPSIS
Test suite for the bundler component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& bundle --version
