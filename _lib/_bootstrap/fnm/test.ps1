$ErrorActionPreference = "Stop"

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm --version
    Write-Output "fnm found"
} else {
    Write-Output "fnm skipped (not found)"
}
