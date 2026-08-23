<#
.SYNOPSIS
Test suite for the gcp component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& gcp --version
