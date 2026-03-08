$ErrorActionPreference = "Stop"

if (Get-Command rust -ErrorAction SilentlyContinue) {
    rust --version
    Write-Output "rust found"
} else {
    Write-Output "rust skipped (not found)"
}
