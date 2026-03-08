$ErrorActionPreference = "Stop"

if (Get-Command swupd -ErrorAction SilentlyContinue) {
    swupd --version
    Write-Output "swupd found"
} else {
    Write-Output "swupd skipped (not found)"
}
