@echo off
:: Windows env stub for apt

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%APT_VERSION%"=="" (
    set "APT_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\apt\%APT_VERSION%\bin;%PATH%"
