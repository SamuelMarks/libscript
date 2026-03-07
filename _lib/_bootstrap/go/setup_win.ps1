if (-Not (Get-Command go -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Go is installed on Windows. Falling back to libscript toolchain setup..."
  & "$PSScriptRoot\..\..\_toolchain\go\setup_win.ps1"
}
