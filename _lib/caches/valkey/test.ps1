<#
.SYNOPSIS
Test suite for the valkey component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& valkey --version
