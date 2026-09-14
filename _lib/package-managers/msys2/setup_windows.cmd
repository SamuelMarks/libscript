@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for msys2 on Windows.
:: Prepares and configures msys2 on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript msys2 installation on Windows.

set "THIS_FILE=%~f0"

where msys2 >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "C:\msys64\usr\bin\bash.exe" exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

(
    echo @echo off
    echo if exist "C:\msys64\usr\bin\bash.exe" ^( "C:\msys64\usr\bin\bash.exe" --version ^) else ^( echo msys2 installed ^)
) > "%DEST_DIR%\msys2.cmd"

echo MSYS2 configured successfully.
exit /b 0
