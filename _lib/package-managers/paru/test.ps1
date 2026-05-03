$ErrorActionPreference = "Stop"

if (Get-Command paru -ErrorAction SilentlyContinue) {
    paru --version
    Write-Output "paru found"
} else {
    Write-Output "paru skipped (not found)"
}
