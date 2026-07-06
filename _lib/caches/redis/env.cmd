@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for redis on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for redis.

:: Windows env stub for redis

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%REDIS_VERSION%"=="" (
    set "REDIS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\redis\%REDIS_VERSION%\bin;%PATH%"
