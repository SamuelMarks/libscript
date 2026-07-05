@echo off
:: Windows env stub for curl

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CURL_VERSION%"=="" (
    set "CURL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\curl\%CURL_VERSION%\bin;%PATH%"
