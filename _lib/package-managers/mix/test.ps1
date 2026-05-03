$ErrorActionPreference = "Stop"

if (Get-Command mix -ErrorAction SilentlyContinue) {
    mix --version
    Write-Output "mix found"
} else {
    Write-Output "mix skipped (not found)"
}
