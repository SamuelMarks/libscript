$ErrorActionPreference = "Stop"

if (Get-Command mas -ErrorAction SilentlyContinue) {
    mas --version
    Write-Output "mas found"
} else {
    Write-Output "mas skipped (not found)"
}
