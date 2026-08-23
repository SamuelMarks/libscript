<#
.SYNOPSIS
Test suite for the awscli component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& aws --version
