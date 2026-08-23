<#
.SYNOPSIS
Test suite for the duckdb component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

duckdb -c "SELECT 1;"
