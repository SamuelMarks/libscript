$ErrorActionPreference = "Stop"

if (Get-Command spack -ErrorAction SilentlyContinue) {
    spack --version
    Write-Output "spack found"
} else {
    Write-Output "spack skipped (not found)"
}
