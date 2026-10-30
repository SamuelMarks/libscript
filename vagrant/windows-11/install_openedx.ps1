# ## Overview
# Installs and tests Open edX in the Windows 11 Vagrant environment.
#
# ## Usage
# .\install_openedx.ps1

$ErrorActionPreference = "Continue"
$LibscriptRoot = if ($env:LIBSCRIPT_ROOT_DIR -and (Test-Path (Join-Path $env:LIBSCRIPT_ROOT_DIR "libscript.cmd"))) {
    $env:LIBSCRIPT_ROOT_DIR
} elseif (Test-Path "C:\libscript\libscript.cmd") {
    "C:\libscript"
} else {
    (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
$LibscriptCmd = Join-Path $LibscriptRoot "libscript.cmd"

Write-Host "Installing openedx..."
& $LibscriptCmd install openedx
$installExit = $LASTEXITCODE

if ($installExit -ne 0) {
  Write-Host "FAILED to install openedx (Exit Code: $installExit)" -ForegroundColor Red
} else {
  Write-Host "SUCCESS: openedx installed" -ForegroundColor Green
  
  Write-Host "Running openedx test..."
  & $LibscriptCmd test openedx
  $testExit = $LASTEXITCODE
  if ($testExit -ne 0) {
    Write-Host "FAILED to test openedx (Exit Code: $testExit)" -ForegroundColor Red
  } else {
    Write-Host "SUCCESS: openedx test" -ForegroundColor Green
  }
}
