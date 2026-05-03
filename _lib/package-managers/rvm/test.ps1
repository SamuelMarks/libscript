$ErrorActionPreference = "Stop"

if (Get-Command rvm -ErrorAction SilentlyContinue) {
    rvm --version
    Write-Output "rvm found"
} else {
    Write-Output "rvm skipped (not found)"
}
