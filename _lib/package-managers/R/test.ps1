$ErrorActionPreference = "Stop"

if (Get-Command R -ErrorAction SilentlyContinue) {
    R --version
    Write-Output "R found"
} else {
    Write-Output "R skipped (not found)"
}
