$ErrorActionPreference = "Stop"

if (Get-Command xpk -ErrorAction SilentlyContinue) {
    xpk --version
} else {
    Write-Host "xpk skipped (not found)"
}
