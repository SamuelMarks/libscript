$ErrorActionPreference = "Stop"

if (Get-Command eopkg -ErrorAction SilentlyContinue) {
    eopkg --version
    Write-Output "eopkg found"
} else {
    Write-Output "eopkg skipped (not found)"
}
