@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for 7zip on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for 7zip.

:: Windows env stub for 7zip
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%SEVENZIP_VERSION%"=="" (
    set "SEVENZIP_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\7zip\%SEVENZIP_VERSION%\bin;%PATH%"
