@echo off
:: # env.cmd
::
:: ## Overview
:: Sets environment variables for MySQL on Windows.
::
:: ## Usage
:: Call or execute in the current command shell:
::   call env.cmd

set "THIS_FILE=%~f0"

if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=openedx"
if "%MYSQL_USER%"=="" set "MYSQL_USER=openedx"
if "%MYSQL_VERSION%"=="" set "MYSQL_VERSION=8.4.11"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if exist "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin" (
    set "PATH=%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin;%PATH%"
)
