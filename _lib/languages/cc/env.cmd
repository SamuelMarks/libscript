@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for CC on Windows.
::
:: ## Usage
:: Sets up default environment variables for CC.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%CC_INSTALL_METHOD%"=="" set "CC_INSTALL_METHOD=system"
if "%CC_VERSION%"=="" set "CC_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "PATH=%LIBSCRIPT_HOME%\cc\%CC_VERSION%\bin;%PATH%"
