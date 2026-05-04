$ErrorActionPreference = "Stop"

if (-Not (Get-Command yarn -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\npm\setup.ps1"
  npm install -g yarn
}
