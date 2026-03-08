[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command coursier -ErrorAction SilentlyContinue) {
    coursier --version
} else {
    Write-Host "coursier skipped (not found)"
}
