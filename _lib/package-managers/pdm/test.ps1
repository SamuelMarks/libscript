$ErrorActionPreference = "Stop"

if (Get-Command pdm -ErrorAction SilentlyContinue) {
    pdm --version
    Write-Output "pdm found"
} else {
    Write-Output "pdm skipped (not found)"
}
