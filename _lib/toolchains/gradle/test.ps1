$ErrorActionPreference = "Stop"

if (Get-Command gradle -ErrorAction SilentlyContinue) {
    gradle --version
    Write-Output "gradle found"
} else {
    Write-Output "gradle skipped (not found)"
}
