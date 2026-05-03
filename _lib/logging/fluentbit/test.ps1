$ErrorActionPreference = "Stop"

if (Get-Command fluentbit -ErrorAction SilentlyContinue) {
    fluentbit --version
    Write-Output "fluentbit found"
} else {
    Write-Output "fluentbit skipped (not found)"
}
