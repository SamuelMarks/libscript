$ErrorActionPreference = "Stop"

if (Get-Command macports -ErrorAction SilentlyContinue) {
    macports --version
    Write-Output "macports found"
} else {
    Write-Output "macports skipped (not found)"
}
