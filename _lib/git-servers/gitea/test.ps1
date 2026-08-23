<#
.SYNOPSIS
Test suite for the gitea component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& gitea --version
