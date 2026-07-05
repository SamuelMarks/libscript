@echo off
:: Windows env stub for openrc

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%OPENRC_VERSION%"=="" (
    set "OPENRC_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\openrc\%OPENRC_VERSION%\bin;%PATH%"
