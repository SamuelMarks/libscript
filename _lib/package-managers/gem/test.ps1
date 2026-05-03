$ErrorActionPreference = "Stop"

if (Get-Command gem -ErrorAction SilentlyContinue) {
    gem --version
    Write-Output "gem found"
} else {
    Write-Output "gem skipped (not found)"
}
