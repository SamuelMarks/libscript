@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Swift on Windows.
::
:: ## Usage
:: Sets `SWIFT_VERSION` and prepends Swift to PATH.
set "THIS_FILE=%~f0"

if "%SWIFT_VERSION%"=="" set SWIFT_VERSION=5.10
if "%SWIFT_VERSION%"=="latest" set SWIFT_VERSION=5.10
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set SWIFT_DIR=%LIBSCRIPT_HOME%\swift\%SWIFT_VERSION%
set PATH=%SWIFT_DIR%\usr\bin;%PATH%
