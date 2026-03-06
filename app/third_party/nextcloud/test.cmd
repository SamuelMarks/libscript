@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\nextcloud"

echo [TEST] Validating Nextcloud on Windows...
if exist "%WWWROOT_CHK%\core" (
    echo [PASS] Nextcloud directory found at %WWWROOT_CHK%
    exit /b 0
) else (
    echo [FAIL] Nextcloud directory not found at %WWWROOT_CHK%
    exit /b 1
)
