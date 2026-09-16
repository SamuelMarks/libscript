# ## Overview
# PowerShell test script for memcached.
#
# ## Usage
# Execute via PowerShell.

$EnvScript = Join-Path $PSScriptRoot "env.ps1"
if (Test-Path $EnvScript) {
    . $EnvScript
}

if (Get-Command memcached -ErrorAction SilentlyContinue) {
    memcached -V
    exit 0
}

$CliScript = Join-Path $PSScriptRoot "cli.cmd"
if (Test-Path $CliScript) {
    & $CliScript --help | Out-Null
}
exit 0
