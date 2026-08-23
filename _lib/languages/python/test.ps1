<#
.SYNOPSIS
Test suite for the python component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

python -c "print('hello world!')"
