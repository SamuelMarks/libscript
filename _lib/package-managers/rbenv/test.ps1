$ErrorActionPreference = "Stop"

if (Get-Command rbenv -ErrorAction SilentlyContinue) {
    rbenv --version
    Write-Output "rbenv found"
} else {
    Write-Output "rbenv skipped (not found)"
}
