$ErrorActionPreference = "Stop"

if (Get-Command apk -ErrorAction SilentlyContinue) {
    apk --version
    Write-Output "apk found"
} else {
    Write-Output "apk skipped (not found)"
}
