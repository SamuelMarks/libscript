$ErrorActionPreference = "Stop"

if (Get-Command swift -ErrorAction SilentlyContinue) {
    swift --version
    Write-Output "swift found"
} else {
    Write-Output "swift skipped (not found)"
}
