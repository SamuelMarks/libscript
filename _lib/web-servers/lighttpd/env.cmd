@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for lighttpd on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for lighttpd.

:: Windows env stub for lighttpd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%LIGHTTPD_VERSION%"=="" (
    set "LIGHTTPD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\lighttpd\%LIGHTTPD_VERSION%\bin;%PATH%"
