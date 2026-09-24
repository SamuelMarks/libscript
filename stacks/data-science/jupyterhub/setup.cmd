@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the JupyterHub data science platform stack on Windows.
:: Installs jupyterhub via Python and configurable-http-proxy via npm if available.
:: 
:: ## Usage
:: Execute this script to install and configure jupyterhub on the local system.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is required for JupyterHub.
    exit /b 1
)

echo [INFO] Installing JupyterHub via Python pip...
python -m pip install --quiet --upgrade jupyterhub
if errorlevel 1 (
    echo [ERROR] Failed to install JupyterHub via pip.
    exit /b 1
)

where npm >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Installing configurable-http-proxy via npm...
    call npm install -g configurable-http-proxy >nul 2>&1
)

set "BIN_DIR=%USERPROFILE%\.libscript\jupyterhub\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"

(
    echo @echo off
    echo python -m jupyterhub %%*
) > "!BIN_DIR!\jupyterhub.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\jupyterhub.cmd" "%USERPROFILE%\.local\bin\jupyterhub.cmd" >nul 2>&1

echo [INFO] JupyterHub setup completed successfully.
exit /b 0
