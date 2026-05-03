$ErrorActionPreference = "Stop"

if (Get-Command cargo -ErrorAction SilentlyContinue) {
    cargo --version
    Write-Output "cargo found"
} else {
    Write-Output "cargo skipped (not found)"
}
