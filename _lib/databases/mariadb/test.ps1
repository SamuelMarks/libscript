<#
.SYNOPSIS
Test suite for the mariadb component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

mysql -u root -e "SELECT 1;"
