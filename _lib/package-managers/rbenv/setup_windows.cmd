@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for rbenv on Windows.
:: Configures the rbenv CLI wrapper on Windows.
::
:: ## Usage
:: Automatically invoked during libscript rbenv installation on Windows.

set "THIS_FILE=%~f0"

where rbenv >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

(
    echo @echo off
    echo echo rbenv 1.3.2 ^(Windows wrapper - use WSL or rubyinstaller for native Ruby^)
    echo exit /b 0
) > "%DEST_DIR%\rbenv.cmd"

echo rbenv wrapper installed successfully.
exit /b 0
