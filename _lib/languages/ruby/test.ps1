<#
.SYNOPSIS
Test suite for the ruby component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

ruby -e "puts 'hello world!'"
