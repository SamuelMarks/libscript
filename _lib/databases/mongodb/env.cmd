@echo off
:: Windows env stub for mongodb

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MONGODB_VERSION%"=="" (
    set "MONGODB_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\mongodb\%MONGODB_VERSION%\bin;%PATH%"
