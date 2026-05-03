$ErrorActionPreference = "Stop"

if (Get-Command kotlin -ErrorAction SilentlyContinue) {
    kotlin --version
    Write-Output "kotlin found"
} else {
    Write-Output "kotlin skipped (not found)"
}
