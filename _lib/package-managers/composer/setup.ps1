if (-Not (Get-Command composer -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\..\`_toolchain\composer\setup.ps1"
}
