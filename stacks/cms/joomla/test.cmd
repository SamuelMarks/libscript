@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set "WWWROOT_CHK=%WWWROOT%"
if "%WWWROOT_CHK%"=="" set "WWWROOT_CHK=C:\inetpub\wwwroot\joomla"

echo [TEST] Validating Joomla on Windows...
if exist "%WWWROOT_CHK%\administrator" (
    echo [PASS] Joomla directory found at %WWWROOT_CHK%
    exit /b 0
) else (
    echo [FAIL] Joomla directory not found at %WWWROOT_CHK%
    exit /b 1
)
