@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Rust on Windows.
::
:: ## Usage
:: Sets `RUST_VERSION` and prepends Rust to PATH.

if "%RUST_VERSION%"=="" set RUST_VERSION=stable
if "%RUST_VERSION%"=="latest" set RUST_VERSION=stable

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)

set "PATH=%LIBSCRIPT_BASE_DIR%\rust\%RUST_VERSION%\bin;%PATH%"