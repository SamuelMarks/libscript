$ErrorActionPreference = "Stop"

if (Get-Command mariadb -ErrorAction SilentlyContinue) {
    mariadb --version
    Write-Output "mariadb found"
} else {
    Write-Output "mariadb skipped (not found)"
}
