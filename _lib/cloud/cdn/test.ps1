<#
.SYNOPSIS
Test suite for the cdn component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& cdn --version
