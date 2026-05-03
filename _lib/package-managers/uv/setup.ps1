if (-Not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host "Installing uv..."
  Invoke-RestMethod -Uri https://astral.sh/uv/install.ps1 | Invoke-Expression
}
