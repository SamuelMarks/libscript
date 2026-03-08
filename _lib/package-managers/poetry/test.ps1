$ErrorActionPreference = "Stop"

if (Get-Command poetry -ErrorAction SilentlyContinue) {
    poetry --version
    Write-Output "poetry found"
} else {
    Write-Output "poetry skipped (not found)"
}
