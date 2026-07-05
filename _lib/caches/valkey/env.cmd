@echo off
:: Windows env stub for valkey

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%VALKEY_VERSION%"=="" (
    set "VALKEY_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\valkey\%VALKEY_VERSION%\bin;%PATH%"
