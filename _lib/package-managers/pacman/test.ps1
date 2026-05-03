$ErrorActionPreference = "Stop"

if (Get-Command pacman -ErrorAction SilentlyContinue) {
    pacman --version
    Write-Output "pacman found"
} else {
    Write-Output "pacman skipped (not found)"
}
