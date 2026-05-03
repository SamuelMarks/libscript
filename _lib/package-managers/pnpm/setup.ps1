if (-Not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\npm\setup.ps1"
  npm install -g pnpm
}
