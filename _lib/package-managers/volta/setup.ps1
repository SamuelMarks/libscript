if (-Not (Get-Command volta -ErrorAction SilentlyContinue)) {
  Write-Host "Installing volta..."
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install Volta.Volta --silent --accept-package-agreements --accept-source-agreements
  } else {
    Write-Host "Error: winget is required to bootstrap volta on Windows."
    exit 1
  }
}
