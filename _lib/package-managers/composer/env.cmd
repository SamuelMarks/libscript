@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for composer on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for composer.

:: Windows env stub for composer
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%COMPOSER_VERSION%"=="" (
    set "COMPOSER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\composer\%COMPOSER_VERSION%\bin;%PATH%"
