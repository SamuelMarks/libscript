[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command lighttpd -ErrorAction SilentlyContinue) {
    lighttpd -v
} else {
    Write-Host "lighttpd skipped (not found)"
}
