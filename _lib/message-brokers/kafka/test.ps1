[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command kafka -ErrorAction SilentlyContinue) {
    kafka-server-start.sh --version
} else {
    Write-Host "kafka skipped (not found)"
}
