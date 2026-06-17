$ErrorActionPreference = "Stop"

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl --version
} else {
    Write-Host "kubectl skipped (not found)"
}
