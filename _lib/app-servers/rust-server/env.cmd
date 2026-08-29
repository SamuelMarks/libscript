@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for rust-server on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for rust-server.

:: Windows env stub for rust-server
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%RUST_SERVER_VERSION%"=="" (
    set "RUST_SERVER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\rust-server\%RUST_SERVER_VERSION%\bin;%PATH%"
