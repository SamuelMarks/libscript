@echo off
:: Windows env stub for caddy

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CADDY_VERSION%"=="" (
    set "CADDY_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\caddy\%CADDY_VERSION%\bin;%PATH%"
