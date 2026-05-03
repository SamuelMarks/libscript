$ErrorActionPreference = "Stop"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker --version
    Write-Output "docker found"
} else {
    Write-Output "docker skipped (not found)"
}
