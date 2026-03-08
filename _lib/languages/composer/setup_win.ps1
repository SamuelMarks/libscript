$ErrorActionPreference = "Stop"

Write-Host "Installing Composer via Winget..."
if (-not (Get-Command "composer" -ErrorAction SilentlyContinue)) {
    winget install --silent --force --id=Composer.Composer --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "Composer is already installed."
}
