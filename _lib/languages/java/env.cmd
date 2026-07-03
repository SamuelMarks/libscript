@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Java on Windows.
::
:: ## Usage
:: Sets `JAVA_HOME` and prepends it to PATH.

if "%JAVA_VERSION%"=="" set JAVA_VERSION=17
if "%JAVA_VERSION%"=="latest" set JAVA_VERSION=21

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)

set "JAVA_HOME=%LIBSCRIPT_BASE_DIR%\java\%JAVA_VERSION%"
set "PATH=%JAVA_HOME%\bin;%PATH%"