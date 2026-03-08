$ErrorActionPreference = "Stop"

if (Get-Command uv -ErrorAction SilentlyContinue) {
    uv --version
    Write-Output "uv found"
} else {
    Write-Output "uv skipped (not found)"
}
