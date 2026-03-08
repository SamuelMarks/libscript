$ErrorActionPreference = "Stop"

if (Get-Command c -ErrorAction SilentlyContinue) {
    c --version
    Write-Output "c found"
} else {
    Write-Output "c skipped (not found)"
}
