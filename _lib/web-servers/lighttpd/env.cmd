@echo off
:: Windows env stub for lighttpd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%LIGHTTPD_VERSION%"=="" (
    set "LIGHTTPD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\lighttpd\%LIGHTTPD_VERSION%\bin;%PATH%"
