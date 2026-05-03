$ErrorActionPreference = "Stop"

if (Get-Command julia -ErrorAction SilentlyContinue) {
    julia --version
    Write-Output "julia found"
} else {
    Write-Output "julia skipped (not found)"
}
