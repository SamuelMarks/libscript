$ErrorActionPreference = "Stop"

if (Get-Command wait4x -ErrorAction SilentlyContinue) {
    wait4x --version
    Write-Output "wait4x found"
} else {
    Write-Output "wait4x skipped (not found)"
}
