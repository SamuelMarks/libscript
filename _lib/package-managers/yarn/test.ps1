$ErrorActionPreference = "Stop"

if (Get-Command yarn -ErrorAction SilentlyContinue) {
    yarn --version
    Write-Output "yarn found"
} else {
    Write-Output "yarn skipped (not found)"
}
