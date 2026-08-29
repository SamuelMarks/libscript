@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for caddy on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for caddy.

:: Windows env stub for caddy
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CADDY_VERSION%"=="" (
    set "CADDY_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\caddy\%CADDY_VERSION%\bin;%PATH%"
