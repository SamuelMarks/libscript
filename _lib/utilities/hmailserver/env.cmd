@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for hMailServer on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%HMAILSERVER_SMTP_PORT%"=="" set "HMAILSERVER_SMTP_PORT=25"
if "%HMAILSERVER_INSTALL_DIR%"=="" set "HMAILSERVER_INSTALL_DIR=%ProgramFiles(x86)%\hMailServer"
if exist "%HMAILSERVER_INSTALL_DIR%\Bin" (
    set "PATH=%HMAILSERVER_INSTALL_DIR%\Bin;%PATH%"
)
