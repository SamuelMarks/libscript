@echo off
:: Windows env stub for nginx

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%NGINX_VERSION%"=="" (
    set "NGINX_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\nginx\%NGINX_VERSION%\bin;%PATH%"
