<#
.SYNOPSIS
Test suite for the gitlab component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& gitlab --version
