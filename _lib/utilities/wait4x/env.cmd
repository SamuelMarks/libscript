@echo off
:: Windows env stub for wait4x

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%WAIT4X_VERSION%"=="" (
    set "WAIT4X_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\wait4x\%WAIT4X_VERSION%\bin;%PATH%"
