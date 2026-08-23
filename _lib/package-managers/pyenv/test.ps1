<#
.SYNOPSIS
Test suite for the pyenv component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& pyenv --version
