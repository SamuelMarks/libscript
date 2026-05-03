$ErrorActionPreference = "Stop"

if (Get-Command pyenv -ErrorAction SilentlyContinue) {
    pyenv --version
    Write-Output "pyenv found"
} else {
    Write-Output "pyenv skipped (not found)"
}
