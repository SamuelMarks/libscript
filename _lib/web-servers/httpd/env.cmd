@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for httpd on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for httpd.

:: Windows env stub for httpd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%HTTPD_VERSION%"=="" (
    set "HTTPD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\httpd\%HTTPD_VERSION%\bin;%PATH%"
