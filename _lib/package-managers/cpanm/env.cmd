@echo off
:: Windows env stub for cpanm

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CPANM_VERSION%"=="" (
    set "CPANM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cpanm\%CPANM_VERSION%\bin;%PATH%"
