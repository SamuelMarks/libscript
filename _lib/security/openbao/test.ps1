<#
.SYNOPSIS
Test suite for the openbao component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& openbao --version
