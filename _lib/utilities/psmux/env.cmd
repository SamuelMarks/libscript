@echo off
:: Windows env stub for psmux

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%PSMUX_VERSION%"=="" (
    set "PSMUX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\psmux\%PSMUX_VERSION%\bin;%PATH%"
