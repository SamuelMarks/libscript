$ErrorActionPreference = "Stop"

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    pnpm --version
    Write-Output "pnpm found"
} else {
    Write-Output "pnpm skipped (not found)"
}
