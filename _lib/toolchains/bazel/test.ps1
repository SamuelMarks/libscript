<#
.SYNOPSIS
Test suite for the bazel component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

bazel --version
