$ErrorActionPreference = "Stop"

if (Get-Command apt -ErrorAction SilentlyContinue) {
    apt --version
    Write-Output "apt found"
} else {
    Write-Output "apt skipped (not found)"
}
