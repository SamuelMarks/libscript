<#
.SYNOPSIS
Test suite for the rebar3 component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& rebar3 --version
