$ErrorActionPreference = "Stop"

if (Get-Command volta -ErrorAction SilentlyContinue) {
    volta --version
    Write-Output "volta found"
} else {
    Write-Output "volta skipped (not found)"
}
