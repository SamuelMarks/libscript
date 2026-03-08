[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command gitea -ErrorAction SilentlyContinue) {
    gitea --version
} else {
    Write-Host "gitea skipped (not found)"
}
