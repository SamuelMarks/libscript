@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

echo Validating PrestaShop installation...
set "WWWROOT=%WWWROOT%"
if "%WWWROOT%"=="" set "WWWROOT=C:\inetpub\wwwroot\prestashop"

if exist "%WWWROOT%\classes\" (
    echo PrestaShop directory found at %WWWROOT%
    exit /b 0
) else if exist "%WWWROOT%\install\" (
    echo PrestaShop directory found at %WWWROOT%
    exit /b 0
) else (
    echo PrestaShop directory not found at %WWWROOT%
    exit /b 1
)
