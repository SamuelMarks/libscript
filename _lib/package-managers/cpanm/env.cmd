@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for cpanm on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for cpanm.

:: Windows env stub for cpanm
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CPANM_VERSION%"=="" (
    set "CPANM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cpanm\%CPANM_VERSION%\bin;%PATH%"
