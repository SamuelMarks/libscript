<#
.SYNOPSIS
Test suite for the elixir component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

elixir -e "IO.puts('hello world!')"
