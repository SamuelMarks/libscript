if (-Not (Get-Command fnm -ErrorAction SilentlyContinue)) {
  Write-Host "Installing fnm..."
  Invoke-Expression (Invoke-RestMethod -Uri "https://fnm.vercel.stacks/install")
}
