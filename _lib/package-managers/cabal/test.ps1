<#
.SYNOPSIS
Test suite for the cabal component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& cabal --version
