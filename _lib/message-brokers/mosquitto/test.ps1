<#
.SYNOPSIS
Test suite for the mosquitto component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& mosquitto --version
