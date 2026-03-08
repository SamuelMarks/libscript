$ErrorActionPreference = "Stop"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop --version
    Write-Output "scoop found"
} else {
    Write-Output "scoop skipped (not found)"
}
