$ErrorActionPreference = "Stop"

if (Get-Command huggingface_hub -ErrorAction SilentlyContinue) {
    huggingface_hub --version
} else {
    Write-Host "huggingface_hub skipped (not found)"
}
