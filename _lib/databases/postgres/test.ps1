$ErrorActionPreference = "Stop"

if (Get-Command postgres -ErrorAction SilentlyContinue) {
    postgres --version
    Write-Output "postgres found"
} else {
    Write-Output "postgres skipped (not found)"
}
