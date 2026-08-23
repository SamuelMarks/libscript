<#
.SYNOPSIS
Test suite for the rustup component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& rustup --version
