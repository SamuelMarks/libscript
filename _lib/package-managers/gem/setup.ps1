if (-Not (Get-Command gem -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Ruby is installed on Windows."
}
