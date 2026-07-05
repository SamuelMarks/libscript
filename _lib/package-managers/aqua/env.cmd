@echo off
:: Windows env stub for aqua

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AQUA_VERSION%"=="" (
    set "AQUA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\aqua\%AQUA_VERSION%\bin;%PATH%"
