$ErrorActionPreference = "Stop"

if (Get-Command vcpkg -ErrorAction SilentlyContinue) {
    vcpkg --version
    Write-Output "vcpkg found"
} else {
    Write-Output "vcpkg skipped (not found)"
}
