<#
.SYNOPSIS
Test suite for the powershell component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& powershell --version
