@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for C on Windows.
::
:: ## Usage
:: Sets up default environment variables for C.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%C_INSTALL_METHOD%"=="" set "C_INSTALL_METHOD=system"
if "%C_VERSION%"=="" set "C_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "PATH=%LIBSCRIPT_HOME%\c\%C_VERSION%\bin;%PATH%"
