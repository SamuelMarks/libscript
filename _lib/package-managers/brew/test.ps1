$ErrorActionPreference = "Stop"

if (Get-Command brew -ErrorAction SilentlyContinue) {
    brew --version
    Write-Output "brew found"
} else {
    Write-Output "brew skipped (not found)"
}
