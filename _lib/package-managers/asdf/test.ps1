<#
.SYNOPSIS
Test suite for the asdf component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& asdf --version
