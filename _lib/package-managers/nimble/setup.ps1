if (-Not (Get-Command nimble -ErrorAction SilentlyContinue)) {
  Write-Host "Installing nimble..."
  Write-Host "Please install Nim for Windows via nimble-lang.org installers or winget install Nim.Nim"
  exit 1
}
