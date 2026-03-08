if (-Not (Get-Command poetry -ErrorAction SilentlyContinue)) {
  Write-Host "Installing poetry..."
  (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | python -
}
