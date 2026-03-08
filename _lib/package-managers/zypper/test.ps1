$ErrorActionPreference = "Stop"

if (Get-Command zypper -ErrorAction SilentlyContinue) {
    zypper --version
    Write-Output "zypper found"
} else {
    Write-Output "zypper skipped (not found)"
}
