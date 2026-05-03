$ErrorActionPreference = "Stop"

if (Get-Command composer -ErrorAction SilentlyContinue) {
    composer --version
    Write-Output "composer found"
} else {
    Write-Output "composer skipped (not found)"
}
