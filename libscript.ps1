$ErrorActionPreference = "Stop"

$LibscriptCmd = Join-Path $PSScriptRoot "libscript.cmd"

if (Test-Path $LibscriptCmd) {
    & $LibscriptCmd @args
} else {
    Write-Error "Could not find libscript.cmd in $PSScriptRoot"
    exit 1
}
