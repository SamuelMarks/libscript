$ErrorActionPreference = "Stop"

if (Get-Command rye -ErrorAction SilentlyContinue) {
    rye --version
    Write-Output "rye found"
} else {
    Write-Output "rye skipped (not found)"
}
