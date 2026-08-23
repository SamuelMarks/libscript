<#
.SYNOPSIS
Test suite for the nodejs component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

node -e "console.log('hello world!')"
