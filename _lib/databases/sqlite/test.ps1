<#
.SYNOPSIS
Test suite for the sqlite component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

sqlite3 :memory: "SELECT 1;"
