@echo off
:: Windows env stub for utils

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%UTILS_VERSION%"=="" (
    set "UTILS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\utils\%UTILS_VERSION%\bin;%PATH%"
