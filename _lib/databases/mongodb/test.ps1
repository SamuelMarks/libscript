<#
.SYNOPSIS
Test suite for the mongodb component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

mongosh --eval "db.runCommand({ ping: 1 })"
