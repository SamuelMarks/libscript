$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget --version
    Write-Output "winget found"
} else {
    Write-Output "winget skipped (not found)"
}
