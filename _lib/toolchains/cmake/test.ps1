[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command cmake -ErrorAction SilentlyContinue) {
    cmake --version
} else {
    Write-Host "cmake skipped (not found)"
}
