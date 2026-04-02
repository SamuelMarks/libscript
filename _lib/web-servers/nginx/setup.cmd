@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_win.ps1"
goto :eof

:native_cmd
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing Nginx natively...
set "PACKAGE_NAME=nginx"
set "NGINX_VER=1.25.3"
if defined NGINX_VERSION set "NGINX_VER=%NGINX_VERSION%"
if "%NGINX_VER%"=="latest" set "NGINX_VER=1.25.3"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\nginx"
if not exist "%PREFIX%" mkdir "%PREFIX%"
set "NGINX_URL=http://nginx.org/download/nginx-%NGINX_VER%.zip"
set "ZIP_FILE=%TEMP%\nginx-%NGINX_VER%.zip"
if not exist "%ZIP_FILE%" (
    echo [INFO] Downloading Nginx %NGINX_VER%...
    call "%~dp0\..\..\..\_lib\_common\pkg_mgr.cmd" :libscript_download "%NGINX_URL%" "%ZIP_FILE%"
)
if exist "%ZIP_FILE%" (
    tar -xf "%ZIP_FILE%" -C "%PREFIX%" --strip-components=1 >nul 2>&1 || powershell -command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%PREFIX%' -Force" >nul 2>&1
    echo [INFO] Nginx installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Nginx.
    exit /b 1
)
