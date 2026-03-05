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
echo [INFO] PowerShell not found. Installing Apache HTTPD natively...
set "HTTPD_VER=2.4.58"
if defined HTTPD_VERSION set "HTTPD_VER=%HTTPD_VERSION%"
if "%HTTPD_VER%"=="latest" set "HTTPD_VER=2.4.58"
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\httpd"
if not exist "%PREFIX%" mkdir "%PREFIX%"
:: Using Apache Haus or Apache Lounge. We use a known mirror or version URL if possible.
:: Actually, zip might be named httpd-2.4.58-win64-VS17.zip
set "HTTPD_URL=https://www.apachelounge.com/download/VS17/binaries/httpd-%HTTPD_VER%-win64-VS17.zip"
set "ZIP_FILE=%TEMP%\httpd-%HTTPD_VER%.zip"
if not exist "%ZIP_FILE%" (
    echo [INFO] Downloading Apache HTTPD %HTTPD_VER%...
    bitsadmin /transfer HttpdDownload /download /priority normal "%HTTPD_URL%" "%ZIP_FILE%" >nul 2>&1 || certutil -urlcache -split -f "%HTTPD_URL%" "%ZIP_FILE%" >nul 2>&1
)
if exist "%ZIP_FILE%" (
    tar -xf "%ZIP_FILE%" -C "%PREFIX%" --strip-components=1 >nul 2>&1 || powershell -command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%PREFIX%' -Force" >nul 2>&1
    echo [INFO] Apache HTTPD installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Apache HTTPD.
    exit /b 1
)
