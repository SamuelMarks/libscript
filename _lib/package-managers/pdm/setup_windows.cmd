@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for pdm on Windows.
:: Prepares and configures pdm on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript pdm installation on Windows.

set "THIS_FILE=%~f0"

where pdm >nul 2>&1
if %errorlevel% equ 0 (
    pdm --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

where python >nul 2>&1
if errorlevel 1 (
    echo Python not found on PATH.
    exit /b 1
)

echo Installing pdm via pip...
python -m pip install --upgrade --quiet pdm
if errorlevel 1 (
    echo Failed to install pdm via pip.
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\pdm\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
(
    echo @echo off
    echo python -m pdm %%*
) > "!BIN_DIR!\pdm.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\pdm.cmd" "%USERPROFILE%\.local\bin\pdm.cmd" >nul 2>&1

exit /b 0
