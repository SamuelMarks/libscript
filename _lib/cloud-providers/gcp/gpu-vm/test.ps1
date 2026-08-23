<#
.SYNOPSIS
Test suite for the gpu-vm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& gpu-vm --version
