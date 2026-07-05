@echo off
:: Windows env stub for awscli

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AWSCLI_VERSION%"=="" (
    set "AWSCLI_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\awscli\%AWSCLI_VERSION%\bin;%PATH%"
