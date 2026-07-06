@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for apt on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for apt.

:: Windows env stub for apt

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%APT_VERSION%"=="" (
    set "APT_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\apt\%APT_VERSION%\bin;%PATH%"
