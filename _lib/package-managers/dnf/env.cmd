@echo off
:: Windows env stub for dnf

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DNF_VERSION%"=="" (
    set "DNF_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\dnf\%DNF_VERSION%\bin;%PATH%"
