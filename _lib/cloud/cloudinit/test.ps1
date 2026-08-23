<#
.SYNOPSIS
Test suite for the cloudinit component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& cloudinit --version
