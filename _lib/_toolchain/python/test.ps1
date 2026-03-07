$ErrorActionPreference = "Stop"

if (Get-Command python -ErrorAction SilentlyContinue) {
    python --version
    Write-Output "python found"
} else {
    Write-Output "python skipped (not found)"
}
