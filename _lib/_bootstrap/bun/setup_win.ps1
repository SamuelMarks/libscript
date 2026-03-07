if (-Not (Get-Command bun -ErrorAction SilentlyContinue)) {
  Write-Host "Installing bun..."
  Invoke-Expression (Invoke-RestMethod -Uri "https://bun.sh/install.ps1")
}
