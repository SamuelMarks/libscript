@echo off
:: Windows env stub for httpd

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%HTTPD_VERSION%"=="" (
    set "HTTPD_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\httpd\%HTTPD_VERSION%\bin;%PATH%"
