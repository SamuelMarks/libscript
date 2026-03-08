if (-Not (Get-Command kubectl-krew -ErrorAction SilentlyContinue)) {
  Write-Host "Installing krew..."
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $krewRoot = "$env:USERPROFILE\.krew"
  $tempDir = Join-Path $env:TEMP "krew"
  New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
  $downloadUrl = "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-windows_amd64.tar.gz"
  $downloadPath = Join-Path $tempDir "krew.tar.gz"
  Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
  tar xvf $downloadPath -C $tempDir
  & (Join-Path $tempDir "krew-windows_amd64.exe") install krew
  Remove-Item -Recurse -Force $tempDir
}
