if (-Not (Get-Command deno -ErrorAction SilentlyContinue)) {
  Write-Host "Installing deno..."
  Invoke-Expression (Invoke-RestMethod -Uri "https://deno.land/install.ps1")
}
