@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for nginx on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for nginx.

:: Windows env stub for nginx
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%NGINX_VERSION%"=="" (
    set "NGINX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\nginx\%NGINX_VERSION%\bin;%PATH%"
