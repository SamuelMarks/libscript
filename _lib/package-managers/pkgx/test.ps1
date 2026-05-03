$ErrorActionPreference = "Stop"

if (Get-Command pkgx -ErrorAction SilentlyContinue) {
    pkgx --version
    Write-Output "pkgx found"
} else {
    Write-Output "pkgx skipped (not found)"
}
