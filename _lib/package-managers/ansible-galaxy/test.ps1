<#
.SYNOPSIS
Test suite for the ansible-galaxy component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& ansible-galaxy --version
