if (-Not (Get-Command ansible-galaxy -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
