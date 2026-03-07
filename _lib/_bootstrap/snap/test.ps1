$ErrorActionPreference = "Stop"

if (Get-Command snap -ErrorAction SilentlyContinue) {
    snap --version
    Write-Output "snap found"
} else {
    Write-Output "snap skipped (not found)"
}
