$ErrorActionPreference = "Stop"

if (Get-Command nvm -ErrorAction SilentlyContinue) {
    nvm --version
    Write-Output "nvm found"
} else {
    Write-Output "nvm skipped (not found)"
}
