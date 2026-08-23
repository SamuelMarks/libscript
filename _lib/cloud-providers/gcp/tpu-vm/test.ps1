<#
.SYNOPSIS
Test suite for the tpu-vm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& tpu-vm --version
