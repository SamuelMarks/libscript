$ErrorActionPreference = "Stop"

if (Get-Command krew -ErrorAction SilentlyContinue) {
    krew --version
    Write-Output "krew found"
} else {
    Write-Output "krew skipped (not found)"
}
