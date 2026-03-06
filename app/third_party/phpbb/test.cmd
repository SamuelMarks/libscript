@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

echo Validating phpBB installation...
set "WWWROOT=%WWWROOT%"
if "%WWWROOT%"=="" set "WWWROOT=C:\inetpub\wwwroot\phpbb"

if exist "%WWWROOT%\phpbb\" (
    echo phpBB directory found at %WWWROOT%
    exit /b 0
) else if exist "%WWWROOT%\install\" (
    echo phpBB directory found at %WWWROOT%
    exit /b 0
) else (
    echo phpBB directory not found at %WWWROOT%
    exit /b 1
)
