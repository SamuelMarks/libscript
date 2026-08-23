<#
.SYNOPSIS
Test suite for the kubernetes-thw component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& kubernetes-thw --version
