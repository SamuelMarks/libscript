$ErrorActionPreference = "Stop"

if (Get-Command ruby -ErrorAction SilentlyContinue) {
    ruby --version
    Write-Output "ruby found"
} else {
    Write-Output "ruby skipped (not found)"
}
