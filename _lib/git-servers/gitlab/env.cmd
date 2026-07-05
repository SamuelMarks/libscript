@echo off
:: Windows env stub for gitlab

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%GITLAB_VERSION%"=="" (
    set "GITLAB_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\gitlab\%GITLAB_VERSION%\bin;%PATH%"
