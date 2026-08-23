<#
.SYNOPSIS
Test suite for the httpd component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& httpd --version
