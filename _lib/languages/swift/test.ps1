<#
.SYNOPSIS
Test suite for the swift component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

swift --version
