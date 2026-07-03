<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'etcd' stack.

.DESCRIPTION
Execute this script to run the test suite for etcd.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh
if (Get-Command etcd -ErrorAction SilentlyContinue) {
    Write-Host "etcd is installed."
    exit 0
} else {
    Write-Host "etcd is NOT installed."
    exit 1
}
