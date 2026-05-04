$ErrorActionPreference = "Stop"

if (Get-Command go -ErrorAction SilentlyContinue) {
    go --version
    Write-Output "go found"
} else {
    Write-Output "go skipped (not found)"
}
