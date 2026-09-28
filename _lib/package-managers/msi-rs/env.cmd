@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the msi-rs component on Windows.
:: Prepends the isolated msi-rs binary directory to the PATH variable.
::
:: ## Usage
:: Call this script to load environment variables into the current Command Prompt session:
::   call env.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%MSI_RS_VERSION%"=="" (
    set "MSI_RS_VERSION=latest"
)

endlocal & set "PATH=%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%\bin;%PATH%"
