if (-Not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\npm\setup_win.ps1"
  npm install -g pnpm
}
