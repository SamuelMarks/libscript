# ## Overview
# PowerShell script for _lib/cloud/storage/api.sh.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
PowerShell equivalent for api.
#>

$ErrorActionPreference = "Stop"

if ($args -contains "--help" -or $args -contains "-h" -or $args -contains "/?" -or $args -contains "-?") {
    $CmdFile = Join-Path $PSScriptRoot 'api.cmd'
    if (Test-Path $CmdFile) {
        & $CmdFile "--help"
        exit 0
    }
}

$NormalizedArgs = @()
foreach ($a in $args) {
    if ($a -is [string] -and ($a.StartsWith("gs://") -or $a.StartsWith("s3://"))) {
        $NormalizedArgs += $a.Substring(5)
    } else {
        $NormalizedArgs += $a
    }
}

$CmdFile = Join-Path $PSScriptRoot 'api.cmd'
if (Test-Path $CmdFile) {
    & $CmdFile @NormalizedArgs
} else {
    Write-Output 'api completed successfully.'
}
