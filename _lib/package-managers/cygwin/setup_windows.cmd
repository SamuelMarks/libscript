@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where cygwin >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "C:\cygwin64\bin\bash.exe" exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Downloading Cygwin setup from https://www.cygwin.com/setup-x86_64.exe...
curl -sSL "https://www.cygwin.com/setup-x86_64.exe" -o "%DEST_DIR%\setup-x86_64.exe"
if errorlevel 1 (
    echo Failed to download Cygwin setup.
    exit /b 1
)

echo Cygwin installer downloaded successfully.
exit /b 0
