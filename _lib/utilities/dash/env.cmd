@echo off
:: Windows env stub for dash

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DASH_VERSION%"=="" (
    set "DASH_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\dash\%DASH_VERSION%\bin;%PATH%"
