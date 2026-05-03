$ErrorActionPreference = "Stop"

if (Get-Command cargo-binstall -ErrorAction SilentlyContinue) {
    cargo-binstall --version
    Write-Output "cargo-binstall found"
} else {
    Write-Output "cargo-binstall skipped (not found)"
}
