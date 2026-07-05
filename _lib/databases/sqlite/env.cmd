@echo off
:: Windows env stub for sqlite

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%SQLITE_VERSION%"=="" (
    set "SQLITE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\sqlite\%SQLITE_VERSION%\bin;%PATH%"
