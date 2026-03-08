$ErrorActionPreference = "Stop"

if (Get-Command bundler -ErrorAction SilentlyContinue) {
    bundler --version
    Write-Output "bundler found"
} else {
    Write-Output "bundler skipped (not found)"
}
