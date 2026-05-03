$ErrorActionPreference = "Stop"

if (Get-Command ghcup -ErrorAction SilentlyContinue) {
    ghcup --version
    Write-Output "ghcup found"
} else {
    Write-Output "ghcup skipped (not found)"
}
