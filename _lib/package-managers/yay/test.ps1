$ErrorActionPreference = "Stop"

if (Get-Command yay -ErrorAction SilentlyContinue) {
    yay --version
    Write-Output "yay found"
} else {
    Write-Output "yay skipped (not found)"
}
