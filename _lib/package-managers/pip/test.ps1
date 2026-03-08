$ErrorActionPreference = "Stop"

if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip --version
    Write-Output "pip found"
} else {
    Write-Output "pip skipped (not found)"
}
