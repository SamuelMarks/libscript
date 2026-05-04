$ErrorActionPreference = "Stop"

$InstallCmd = Join-Path $PSScriptRoot "install.cmd"

if (Test-Path $InstallCmd) {
    & $InstallCmd @args
} else {
    Write-Error "Could not find install.cmd in $PSScriptRoot"
    exit 1
}
