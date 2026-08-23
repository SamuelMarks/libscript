<#
.SYNOPSIS
Test suite for the vllm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& vllm --version
