$ErrorActionPreference = "Stop"

if (Get-Command deno -ErrorAction SilentlyContinue) {
    deno --version
    Write-Output "deno found"
} else {
    Write-Output "deno skipped (not found)"
}
