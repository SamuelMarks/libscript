@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for postgres on Windows.
:: Prepares and configures postgres on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript postgres installation on Windows.

set "THIS_FILE=%~f0"

where psql >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"
if not exist "%DEST_DIR%\bin" mkdir "%DEST_DIR%\bin"

set "URL=https://get.enterprisedb.com/postgresql/postgresql-16.6-1-windows-x64-binaries.zip"
set "TEMP_ZIP=%TEMP%\postgresql.zip"

echo Downloading PostgreSQL binaries from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download PostgreSQL.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\pgsql\bin\psql.exe" (
    (
        echo @echo off
        echo "%DEST_DIR%\pgsql\bin\psql.exe" %%*
    ) > "%DEST_DIR%\bin\psql.cmd"
    echo PostgreSQL installed successfully.
    exit /b 0
)

exit /b 1
