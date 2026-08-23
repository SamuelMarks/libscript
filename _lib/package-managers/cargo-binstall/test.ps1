<#
.SYNOPSIS
Test suite for the cargo-binstall component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& cargo-binstall -V
