@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for coursier on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for coursier.

:: Windows env stub for coursier
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%COURSIER_VERSION%"=="" (
    set "COURSIER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\coursier\%COURSIER_VERSION%\bin;%PATH%"
