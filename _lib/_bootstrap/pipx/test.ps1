$ErrorActionPreference = "Stop"

if (Get-Command pipx -ErrorAction SilentlyContinue) {
    pipx --version
    Write-Output "pipx found"
} else {
    Write-Output "pipx skipped (not found)"
}
