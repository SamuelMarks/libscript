$ErrorActionPreference = "Stop"

if (Get-Command aqua -ErrorAction SilentlyContinue) {
    aqua -v
    Write-Output "aqua found"
} else {
    Write-Output "aqua skipped (not found)"
}
