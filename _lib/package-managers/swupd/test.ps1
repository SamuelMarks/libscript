<#
.SYNOPSIS
Test suite for the swupd component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& swupd --version
