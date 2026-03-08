if (-Not (Get-Command pip -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Python is installed on Windows."
}
