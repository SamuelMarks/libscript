<#
.SYNOPSIS
Test suite for the coursier component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

cs --version
