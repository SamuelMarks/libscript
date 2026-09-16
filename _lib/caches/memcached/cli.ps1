# ## Overview
# PowerShell CLI entrypoint for memcached.
#
# ## Usage
# Execute via PowerShell.

$env:PACKAGE_NAME = "memcached"
$CoreScript = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "..") "_common\component_core.ps1"
if (Test-Path $CoreScript) {
    & $CoreScript $args
} else {
    Write-Error "component_core.ps1 not found."
}
