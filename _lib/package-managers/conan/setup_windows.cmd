@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for conan on Windows.
:: Prepares and configures conan on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript conan installation on Windows.

set "THIS_FILE=%~f0"

where conan >nul 2>&1
if %errorlevel% equ 0 (
    conan --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

where python >nul 2>&1
if errorlevel 1 (
    echo Python not found on PATH.
    exit /b 1
)

echo Installing conan via pip...
python -m pip install --upgrade --quiet conan
if errorlevel 1 (
    echo Failed to install conan via pip.
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\conan\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"

(
    echo @echo off
    echo python -m conans.conan %%*
) > "!BIN_DIR!\conan.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\conan.cmd" "%USERPROFILE%\.local\bin\conan.cmd" >nul 2>&1

exit /b 0
