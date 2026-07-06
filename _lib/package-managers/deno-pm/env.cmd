@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for deno-pm on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for deno-pm.

:: Windows env stub for deno-pm

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DENO_PM_VERSION%"=="" (
    set "DENO_PM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\deno-pm\%DENO_PM_VERSION%\bin;%PATH%"
