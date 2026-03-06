@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\magento"

echo [TEST] Validating Magento on Windows...
if exist "%WWWROOT_CHK%\app" (
    echo [PASS] Magento directory found at %WWWROOT_CHK%
    exit /b 0
) else (
    echo [FAIL] Magento directory not found at %WWWROOT_CHK%
    exit /b 1
)
