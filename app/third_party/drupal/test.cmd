@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\drupal"

echo [TEST] Validating Drupal on Windows...
if exist "%WWWROOT_CHK%\core" (
    echo [PASS] Drupal directory found at %WWWROOT_CHK%
    exit /b 0
) else (
    echo [FAIL] Drupal directory not found at %WWWROOT_CHK%
    exit /b 1
)
