@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for rust-server on Windows.
:: Prepares and configures rust-server on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript rust-server installation on Windows.

set "THIS_FILE=%~f0"

where cargo >nul 2>&1
if %errorlevel% equ 0 (
    echo Rust server environment verified.
    exit /b 0
)

echo Rust/Cargo not found. Installing rust...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install rust
exit /b %errorlevel%
