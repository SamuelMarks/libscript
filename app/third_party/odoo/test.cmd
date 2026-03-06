@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\odoo"

echo [TEST] Validating Odoo on Windows...
if exist "%WWWROOT_CHK%\odoo-bin" (
    echo [PASS] Odoo directory found at %WWWROOT_CHK%
    exit /b 0
) else (
    echo [FAIL] Odoo directory not found at %WWWROOT_CHK%
    exit /b 1
)