[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command mosquitto -ErrorAction SilentlyContinue) {
    mosquitto -h
} else {
    Write-Host "mosquitto skipped (not found)"
}
