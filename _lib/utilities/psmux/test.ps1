$ErrorActionPreference = "Stop"

if (Get-Command psmux -ErrorAction SilentlyContinue) {
    psmux -V
    Write-Output "psmux found"
} else {
    Write-Output "psmux skipped (not found)"
}
