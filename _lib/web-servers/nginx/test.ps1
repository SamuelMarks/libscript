$ErrorActionPreference = "Stop"

if (Get-Command nginx -ErrorAction SilentlyContinue) {
    nginx --version
    Write-Output "nginx found"
} else {
    Write-Output "nginx skipped (not found)"
}
