$ErrorActionPreference = "Stop"

if (-Not (Get-Command julia -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
