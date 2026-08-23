<#
.SYNOPSIS
Test suite for the filestore component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& filestore --version
