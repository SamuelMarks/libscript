@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for rvm on Windows.
:: Configures the rvm CLI wrapper on Windows.
::
:: ## Usage
:: Automatically invoked during libscript rvm installation on Windows.

set "THIS_FILE=%~f0"

where rvm >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

(
    echo @echo off
    echo echo rvm 1.29.12 ^(Windows wrapper - use WSL or rubyinstaller for native Ruby^)
    echo exit /b 0
) > "%DEST_DIR%\rvm.cmd"

echo rvm wrapper installed successfully.
exit /b 0
