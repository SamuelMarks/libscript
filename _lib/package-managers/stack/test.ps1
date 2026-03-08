$ErrorActionPreference = "Stop"

if (Get-Command stack -ErrorAction SilentlyContinue) {
    stack --version
    Write-Output "stack found"
} else {
    Write-Output "stack skipped (not found)"
}
