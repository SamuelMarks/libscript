<#
.SYNOPSIS
Test suite for the tensorboard component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& tensorboard --version
