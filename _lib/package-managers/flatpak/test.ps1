$ErrorActionPreference = "Stop"

if (Get-Command flatpak -ErrorAction SilentlyContinue) {
    flatpak --version
    Write-Output "flatpak found"
} else {
    Write-Output "flatpak skipped (not found)"
}
