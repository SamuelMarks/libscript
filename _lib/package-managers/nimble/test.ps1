$ErrorActionPreference = "Stop"

if (Get-Command nimble -ErrorAction SilentlyContinue) {
    nimble --version
    Write-Output "nimble found"
} else {
    Write-Output "nimble skipped (not found)"
}
