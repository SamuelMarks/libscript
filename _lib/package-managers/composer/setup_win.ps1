if (-Not (Get-Command composer -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\..\`_toolchain\composer\setup_win.ps1"
}
