$ErrorActionPreference = "Stop"

if (Get-Command dnf -ErrorAction SilentlyContinue) {
    dnf --version
    Write-Output "dnf found"
} else {
    Write-Output "dnf skipped (not found)"
}
