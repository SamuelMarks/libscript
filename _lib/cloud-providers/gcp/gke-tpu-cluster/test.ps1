<#
.SYNOPSIS
Test suite for the gke-tpu-cluster component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

& gke-tpu-cluster --version
