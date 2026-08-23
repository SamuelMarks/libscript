<#
.SYNOPSIS
Test suite for the sh component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

sh --version
