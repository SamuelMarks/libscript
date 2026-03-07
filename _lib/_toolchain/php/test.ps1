$ErrorActionPreference = "Stop"

if (Get-Command php -ErrorAction SilentlyContinue) {
    php --version
    Write-Output "php found"
} else {
    Write-Output "php skipped (not found)"
}
