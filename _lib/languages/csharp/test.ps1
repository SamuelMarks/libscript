<#
.SYNOPSIS
Test suite for the csharp component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

dotnet --version
