@echo off
:: Windows env stub for cygwin

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CYGWIN_VERSION%"=="" (
    set "CYGWIN_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cygwin\%CYGWIN_VERSION%\bin;%PATH%"
