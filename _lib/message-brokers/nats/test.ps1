[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command nats-server -ErrorAction SilentlyContinue) {
    nats-server --version
} else {
    Write-Host "nats skipped (not found)"
}
