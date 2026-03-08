$ErrorActionPreference = "Stop"

if (Get-Command nodejs -ErrorAction SilentlyContinue) {
    nodejs --version
    Write-Output "nodejs found"
} else {
    Write-Output "nodejs skipped (not found)"
}
