$ErrorActionPreference = "Stop"

if (Get-Command helm -ErrorAction SilentlyContinue) {
    helm --version
    Write-Output "helm found"
} else {
    Write-Output "helm skipped (not found)"
}
