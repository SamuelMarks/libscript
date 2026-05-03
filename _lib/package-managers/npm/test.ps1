$ErrorActionPreference = "Stop"

if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm --version
    Write-Output "npm found"
} else {
    Write-Output "npm skipped (not found)"
}
