<#
.SYNOPSIS
Test suite for the kubectl component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& kubectl --version
