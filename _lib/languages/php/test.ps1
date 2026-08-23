<#
.SYNOPSIS
Test suite for the php component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

php -r "echo 'hello world!';"
