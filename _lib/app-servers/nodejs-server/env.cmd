@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for nodejs-server on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for nodejs-server.

:: Windows env stub for nodejs-server

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%NODEJS_SERVER_VERSION%"=="" (
    set "NODEJS_SERVER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\nodejs-server\%NODEJS_SERVER_VERSION%\bin;%PATH%"
