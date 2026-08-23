<#
.SYNOPSIS
Test suite for the gcsfuse component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& gcsfuse --version
