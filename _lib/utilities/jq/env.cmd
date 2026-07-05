@echo off
:: Windows env stub for jq

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%JQ_VERSION%"=="" (
    set "JQ_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\jq\%JQ_VERSION%\bin;%PATH%"
