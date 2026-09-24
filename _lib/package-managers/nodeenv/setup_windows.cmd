@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for nodeenv on Windows.
:: Prepares and configures nodeenv on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript nodeenv installation on Windows.

set "THIS_FILE=%~f0"

where nodeenv >nul 2>&1
if %errorlevel% equ 0 (
    nodeenv --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

where python >nul 2>&1
if errorlevel 1 (
    echo Python not found on PATH.
    exit /b 1
)

echo Installing nodeenv via pip...
python -m pip install --upgrade --quiet nodeenv
if errorlevel 1 (
    echo Failed to install nodeenv via pip.
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\nodeenv\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
(
    echo @echo off
    echo python -m nodeenv %%*
) > "!BIN_DIR!\nodeenv.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\nodeenv.cmd" "%USERPROFILE%\.local\bin\nodeenv.cmd" >nul 2>&1

exit /b 0
