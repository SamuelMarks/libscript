[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command redis -ErrorAction SilentlyContinue) {
    redis-server --version
} else {
    Write-Host "redis skipped (not found)"
}
