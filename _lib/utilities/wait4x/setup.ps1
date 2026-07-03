<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'wait4x' stack.

.DESCRIPTION
Execute this script to install and configure wait4x on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

scoop install wait4x
