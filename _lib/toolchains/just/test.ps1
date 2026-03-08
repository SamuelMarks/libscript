[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command just -ErrorAction SilentlyContinue) {
    just --version
} else {
    Write-Host "just skipped (not found)"
}
