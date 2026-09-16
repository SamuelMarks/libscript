@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for memcached on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for memcached.

:: Windows env stub for memcached
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MEMCACHED_VERSION%"=="" (
    set "MEMCACHED_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\memcached\%MEMCACHED_VERSION%\bin;%PATH%"
