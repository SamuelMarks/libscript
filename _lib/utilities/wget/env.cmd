@echo off
:: Windows env stub for wget

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%WGET_VERSION%"=="" (
    set "WGET_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\wget\%WGET_VERSION%\bin;%PATH%"
