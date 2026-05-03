$ErrorActionPreference = "Stop"

if (Get-Command maven -ErrorAction SilentlyContinue) {
    maven --version
    Write-Output "maven found"
} else {
    Write-Output "maven skipped (not found)"
}
