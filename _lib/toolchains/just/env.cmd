@echo off
:: Windows env stub for just

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%JUST_VERSION%"=="" (
    set "JUST_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\just\%JUST_VERSION%\bin;%PATH%"
