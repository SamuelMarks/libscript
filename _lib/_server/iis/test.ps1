$ErrorActionPreference = "Stop"

if (Get-Command iis -ErrorAction SilentlyContinue) {
    iis --version
    Write-Output "iis found"
} else {
    Write-Output "iis skipped (not found)"
}
