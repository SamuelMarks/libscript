@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for huggingface-cli on Windows.
:: Prepares and configures huggingface-cli on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript huggingface-cli installation on Windows.

set "THIS_FILE=%~f0"

where huggingface-cli >nul 2>&1
if %errorlevel% equ 0 (
    huggingface-cli --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)

where python >nul 2>&1
if errorlevel 1 (
    echo Python not found on PATH.
    exit /b 1
)

echo Installing huggingface_hub via pip...
python -m pip install --upgrade --quiet huggingface_hub
if errorlevel 1 (
    echo Failed to install huggingface_hub via pip.
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\huggingface-cli\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
(
    echo @echo off
    echo python -m huggingface_hub.cli.hf %%*
) > "!BIN_DIR!\huggingface-cli.cmd"

copy /y "!BIN_DIR!\huggingface-cli.cmd" "!BIN_DIR!\hf.cmd" >nul 2>&1

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\huggingface-cli.cmd" "%USERPROFILE%\.local\bin\huggingface-cli.cmd" >nul 2>&1
copy /y "!BIN_DIR!\hf.cmd" "%USERPROFILE%\.local\bin\hf.cmd" >nul 2>&1

exit /b 0
