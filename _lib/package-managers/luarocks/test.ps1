$ErrorActionPreference = "Stop"

if (Get-Command luarocks -ErrorAction SilentlyContinue) {
    luarocks --version
    Write-Output "luarocks found"
} else {
    Write-Output "luarocks skipped (not found)"
}
