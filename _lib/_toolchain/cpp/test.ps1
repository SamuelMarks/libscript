$ErrorActionPreference = "Stop"

if (Get-Command cpp -ErrorAction SilentlyContinue) {
    cpp --version
    Write-Output "cpp found"
} else {
    Write-Output "cpp skipped (not found)"
}
