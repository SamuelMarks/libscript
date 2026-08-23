<#
.SYNOPSIS
Test suite for the gradle component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

gradle --version
