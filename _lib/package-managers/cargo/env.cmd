@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for cargo on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for cargo.

:: Windows env stub for cargo

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CARGO_VERSION%"=="" (
    set "CARGO_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cargo\%CARGO_VERSION%\bin;%PATH%"
