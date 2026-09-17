@echo off
:: # env.cmd
::
:: ## Overview
:: Environment configuration script for kubectl on Windows.
::
:: ## Usage
:: Configures LIBSCRIPT_HOME and PATH for kubectl.

set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KUBECTL_VERSION%"=="" (
    set "KUBECTL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kubectl\%KUBECTL_VERSION%\bin;%PATH%"
