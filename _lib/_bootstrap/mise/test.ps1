$ErrorActionPreference = "Stop"

if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise --version
    Write-Output "mise found"
} else {
    Write-Output "mise skipped (not found)"
}
