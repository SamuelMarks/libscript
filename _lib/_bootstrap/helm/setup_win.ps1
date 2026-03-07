if (-Not (Get-Command helm -ErrorAction SilentlyContinue)) {
  Write-Host "Installing helm via choco (if available)..."
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install kubernetes-helm -y
  } else {
    Write-Host "Please install helm manually or via Winget/Chocolatey."
  }
}
