@echo off
setlocal EnableDelayedExpansion

:: ## Overview
:: Tests genuine WordPress PHP execution by sending a request to the installer.
::
:: ## Usage
:: tests\test_wordpress_genuine.cmd

set "THIS_FILE=%~f0"

echo [INFO] Testing genuine WordPress PHP execution...
powershell -NoProfile -Command "$res = Invoke-WebRequest -Uri 'http://localhost:80/wp-admin/install.php' -UseBasicParsing; if ($res.StatusCode -ne 200) { exit 1 }"
if errorlevel 1 (
  echo [ERROR] WordPress install.php did not return 200 OK. >&2
  exit /b 1
)
echo [PASS] Genuine WordPress execution confirmed.
