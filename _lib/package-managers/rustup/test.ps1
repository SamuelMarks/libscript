$ErrorActionPreference = "Stop"

if (Get-Command rustup -ErrorAction SilentlyContinue) {
    rustup --version
    Write-Output "rustup found"
} else {
    Write-Output "rustup skipped (not found)"
}
