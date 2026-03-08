[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command minio -ErrorAction SilentlyContinue) {
    minio --version
} else {
    Write-Host "minio skipped (not found)"
}
