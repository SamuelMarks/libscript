$ErrorActionPreference = "Stop"

if (Get-Command caddy -ErrorAction SilentlyContinue) {
    caddy --version
    Write-Output "caddy found"
} else {
    Write-Output "caddy skipped (not found)"
}
