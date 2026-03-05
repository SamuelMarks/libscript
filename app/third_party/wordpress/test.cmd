@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\wordpress"

echo [TEST] Validating WordPress on Windows...
if exist "%WWWROOT_CHK%\wp-admin" (
    echo [PASS] WordPress directory found at %WWWROOT_CHK%
    exit /b 0
) else (
    echo [FAIL] WordPress directory not found at %WWWROOT_CHK%
    exit /b 1
)
