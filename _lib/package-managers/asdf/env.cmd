@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for asdf on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for asdf.

:: Windows env stub for asdf
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%ASDF_VERSION%"=="" (
    set "ASDF_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\asdf\%ASDF_VERSION%\bin;%PATH%"
