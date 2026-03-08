$ErrorActionPreference = "Stop"

if (Get-Command openbao -ErrorAction SilentlyContinue) {
    openbao --version
    Write-Output "openbao found"
} else {
    Write-Output "openbao skipped (not found)"
}
