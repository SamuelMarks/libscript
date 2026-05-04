$ErrorActionPreference = "Stop"

if (-Not (Get-Command ghcup -ErrorAction SilentlyContinue)) {
  Write-Host "Installing ghcup..."
  $env:GHCUP_BOOTSTRAP_HASKELL_NONINTERACTIVE=1
  $env:GHCUP_BOOTSTRAP_HASKELL_MINIMAL=1
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  try {
    Invoke-Command -ScriptBlock ([ScriptBlock]::Create((Invoke-WebRequest https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1 -UseBasicParsing))) -ArgumentList $true
  } catch {
    Write-Error $_
    exit 1
  }
}
