@echo off
:: Windows env stub for aws

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AWS_VERSION%"=="" (
    set "AWS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\aws\%AWS_VERSION%\bin;%PATH%"
