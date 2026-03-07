$ErrorActionPreference = "Stop"

if (Get-Command hatch -ErrorAction SilentlyContinue) {
    hatch --version
    Write-Output "hatch found"
} else {
    Write-Output "hatch skipped (not found)"
}
