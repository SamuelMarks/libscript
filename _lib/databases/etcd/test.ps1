<#
.SYNOPSIS
Test suite for the etcd component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

etcdctl version
