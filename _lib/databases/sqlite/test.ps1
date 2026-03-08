$ErrorActionPreference = "Stop"

if (Get-Command sqlite -ErrorAction SilentlyContinue) {
    sqlite --version
    Write-Output "sqlite found"
} else {
    Write-Output "sqlite skipped (not found)"
}
