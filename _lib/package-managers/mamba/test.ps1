$ErrorActionPreference = "Stop"

if (Get-Command micromamba -ErrorAction SilentlyContinue) {
    micromamba --version
    Write-Output "mamba found"
} else {
    Write-Output "mamba skipped (not found)"
}
