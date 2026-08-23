<#
.SYNOPSIS
Test suite for the jetstream component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& jetstream --version
