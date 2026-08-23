<#
.SYNOPSIS
Test suite for the huggingface-cli component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

huggingface-cli --version
