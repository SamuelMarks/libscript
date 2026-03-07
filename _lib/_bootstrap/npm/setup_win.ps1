if (-Not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
