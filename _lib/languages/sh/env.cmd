@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for SH/Dash on Windows.
::
:: ## Usage
:: Sets `SH_VERSION` and prepends SH to PATH.
set "THIS_FILE=%~f0"

if "%SH_VERSION%"=="" set SH_VERSION=0.5.12
if "%SH_VERSION%"=="latest" set SH_VERSION=0.5.12
if "%LIBSCRIPT_HOME%"=="" set LIBSCRIPT_HOME=%USERPROFILE%\.libscript

set PATH=%LIBSCRIPT_HOME%\sh\%SH_VERSION%\bin;%PATH%
