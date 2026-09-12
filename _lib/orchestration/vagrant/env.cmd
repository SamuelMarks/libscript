@echo off
:: # env.cmd
::
:: ## Overview
:: Environment export script for Vagrant on Windows.
::
:: ## Usage
:: Call this script to set Vagrant environment variables.

set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%VAGRANT_VERSION%"=="" (
    set "VAGRANT_VERSION=latest"
)
if exist "%LIBSCRIPT_HOME%\vagrant\%VAGRANT_VERSION%\bin" (
    set "PATH=%LIBSCRIPT_HOME%\vagrant\%VAGRANT_VERSION%\bin;%PATH%"
)
