if (-Not (Get-Command cargo -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Rust is installed on Windows."
}
