<#
.SYNOPSIS
Test suite for the deno component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

deno --version
