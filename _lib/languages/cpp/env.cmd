@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for CPP on Windows.
::
:: ## Usage
:: Sets up default environment variables for CPP.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%CPP_INSTALL_METHOD%"=="" set "CPP_INSTALL_METHOD=system"
if "%CPP_VERSION%"=="" set "CPP_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "PATH=%LIBSCRIPT_HOME%\cpp\%CPP_VERSION%\bin;%PATH%"
