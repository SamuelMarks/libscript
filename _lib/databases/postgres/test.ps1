<#
.SYNOPSIS
Test suite for the postgres component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

psql -c "SELECT 1;"
