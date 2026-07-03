<#
.SYNOPSIS
Provides a generic, cross-platform setup mechanism for the component 'asdf' stack.

.DESCRIPTION
Execute this script to perform generic initialization steps for asdf.
#>

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) {
    $Action = "install"
}

switch ($Action) {
    "ls" {
        Write-Host "[ls] asdf is not supported natively on Windows."
        break
    }
    "ls-remote" {
        Write-Host "[ls-remote] asdf is not supported natively on Windows."
        break
    }
    "use" {
        Write-Host "[use] asdf is not supported natively on Windows."
        break
    }
    default {
        Write-Host "asdf is not supported natively on Windows. Use mise or scoop instead."
        exit 1
    }
}
