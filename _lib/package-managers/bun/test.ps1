$ErrorActionPreference = "Stop"

if (Get-Command bun -ErrorAction SilentlyContinue) {
    bun --version
    Write-Output "bun found"
} else {
    Write-Output "bun skipped (not found)"
}
