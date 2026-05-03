$ErrorActionPreference = "Stop"

if (Get-Command cc -ErrorAction SilentlyContinue) {
    cc --version
    Write-Output "cc found"
} else {
    Write-Output "cc skipped (not found)"
}
