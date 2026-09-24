@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for Apache HTTP Server (httpd) on Windows.
:: Installs Apache HTTP Server via Chocolatey and provisions executable shims.
::
:: ## Usage
:: Automatically invoked during libscript httpd installation on Windows.

set "THIS_FILE=%~f0"

where httpd >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "%APPDATA%\Apache24\bin\httpd.exe" goto :create_shims
if exist "C:\Apache24\bin\httpd.exe" goto :create_shims
if exist "%ProgramFiles%\Apache24\bin\httpd.exe" goto :create_shims

echo Installing Apache HTTP Server via Chocolatey...
where choco >nul 2>&1
if not errorlevel 1 (
    choco install apache-httpd -y --no-progress
)

:create_shims
set "HTTPD_BIN="
if exist "%APPDATA%\Apache24\bin\httpd.exe" set "HTTPD_BIN=%APPDATA%\Apache24\bin"
if exist "C:\Apache24\bin\httpd.exe" set "HTTPD_BIN=C:\Apache24\bin"
if exist "%ProgramFiles%\Apache24\bin\httpd.exe" set "HTTPD_BIN=%ProgramFiles%\Apache24\bin"

if defined HTTPD_BIN (
    set "DEST_DIR=%USERPROFILE%\.libscript\httpd\latest\bin"
    if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
    (
        echo @echo off
        echo "!HTTPD_BIN!\httpd.exe" %%*
    ) > "!DEST_DIR!\httpd.cmd"

    (
        echo @echo off
        echo "!HTTPD_BIN!\httpd.exe" %%*
    ) > "!DEST_DIR!\apachectl.cmd"

    if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
    copy /y "!DEST_DIR!\httpd.cmd" "%USERPROFILE%\.local\bin\httpd.cmd" >nul 2>&1
    copy /y "!DEST_DIR!\apachectl.cmd" "%USERPROFILE%\.local\bin\apachectl.cmd" >nul 2>&1

    echo Apache HTTP Server installed successfully.
    exit /b 0
)

echo Failed to locate Apache HTTP Server.
exit /b 1
