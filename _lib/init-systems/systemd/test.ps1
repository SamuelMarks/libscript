<#
.SYNOPSIS
Test suite for the systemd component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& systemd --version
