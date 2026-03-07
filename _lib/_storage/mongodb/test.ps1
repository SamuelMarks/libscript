$ErrorActionPreference = "Stop"

if (Get-Command mongodb -ErrorAction SilentlyContinue) {
    mongodb --version
    Write-Output "mongodb found"
} else {
    Write-Output "mongodb skipped (not found)"
}
