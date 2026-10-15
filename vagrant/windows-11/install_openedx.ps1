# ## Overview
# Installs and tests Open edX in the Windows 11 Vagrant environment.
#
# ## Usage
# .\install_openedx.ps1

$ErrorActionPreference = "Continue"
Write-Host "Installing openedx..."
& "C:\libscript\libscript.cmd" install openedx
$installExit = $LASTEXITCODE

if ($installExit -ne 0) {
  Write-Host "FAILED to install openedx (Exit Code: $installExit)" -ForegroundColor Red
} else {
  Write-Host "SUCCESS: openedx installed" -ForegroundColor Green
  
  Write-Host "Running openedx test..."
  & "C:\libscript\libscript.cmd" test openedx
  $testExit = $LASTEXITCODE
  if ($testExit -ne 0) {
    Write-Host "FAILED to test openedx (Exit Code: $testExit)" -ForegroundColor Red
  } else {
    Write-Host "SUCCESS: openedx test" -ForegroundColor Green
  }
}
